import {User} from '../models/user.models.js'
import jwt from 'jsonwebtoken'
import nodemailer from 'nodemailer'

function generateToken(id){
    return jwt.sign({id},process.env.ACCESS_TOKEN_SECRET,{expiresIn: process.env.REFRESH_TOKEN_EXPIRY})
}

const transporter = nodemailer.createTransport({
    host: 'smtp.rediffmail.com', // Rediffmail's SMTP server
    port: 465, // Use 465 for SSL, 587 for TLS
    secure: true, // Set to true for SSL (port 465), false for TLS (port 587)
    auth: {
        user: process.env.RediffMail_id, // Replace with your Rediffmail email
        pass: process.env.RediffMail_pass, // Replace with your Rediffmail password
  },
});

const otpStore = new Map();

const registerUser = async(req,res) => {
const {email} = req.body
try {
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "User already registered with this mobile number" });
        }

        const otp = Math.floor(100000 + Math.random() * 900000).toString(); 
        otpStore.set(email, otp); 

        await transporter.sendMail({
            from: process.env.RediffMail_id,
            to: email,
            subject: 'OTP for Registration',
            text: `Your OTP is: ${otp}`,
        });

        res.status(200).json({ message: "OTP sent successfully" });
    } catch (error) {
        console.error("Error sending OTP:", error);
        res.status(500).json({ message: "Failed to send OTP", error });
    }
}

const verifyOtp = async(req,res) => {
    const { email, otp, password } = req.body;

try {
        if (!email || !password || !otp) {
            return res.status(400).json({ message: "All fields are required" });
        }

        if (otpStore.has(email) && otpStore.get(email) === otp) {
            const user = await User.create({ email, password });

            const createdUser = await User.findById(user._id).select("-password");

            if (!createdUser) {
                return res.status(400).json({ message: "User creation failed" });
            }

            const options = {
                httpOnly: true,
                secure: true,
                maxAge: 24*60*60*1000
            };
            const accessToken = generateToken(createdUser._id);

            otpStore.delete(email);

            return res.status(200).cookie("accessToken", accessToken, options).json({ message: "User registered successfully", createdUser, accessToken });
        } else {
            return res.status(400).json({ message: "Invalid OTP or OTP has expired" });
        }
    } catch (error) {
        console.error("Error during OTP verification:", error);
        return res.status(500).json({ message: "An error occurred during OTP verification", error });
    }
}

const loginUser = async(req,res) => {
const {email, password} = req.body

if(!email || !password){
    return res.status(400).json({message: "Input Fields are empty"})
}

const existedUser = await User.findOne({email})

if(!existedUser){
   return res.status(400).json({message: "User does not exist by this username/email", errorData: "User does Not exist"})
}

const isPasswordValid = await existedUser.matchPassword(password)

if(!isPasswordValid){
    return res.status(400).json({message: "Password is incorrect", errorData: "Password is incorrect"})
}

const options = {
    httpOnly: true,
    secure: false,
    maxAge: 24*60*60*1000
}

const loggedInUser = await User.findById(existedUser._id).select("-password")

const accessToken = generateToken(loggedInUser._id)

return res.status(200).cookie("accessToken",accessToken,options).json({message: 'LoggedIn Successfully',loggedInUser,accessToken})
}

export {registerUser,loginUser,verifyOtp}