import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { Router } from 'express';

const NdrfEmployeeSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true },
    Name: {type: String},
    email: {type: String, unique: true},
    phoneNo: {type: String, unique: true},
    address: {type: String},
    password: { type: String, required: true },
  },
  {timestamps: true }
);

// Hash password before saving to the database
// NdrfEmployeeSchema.pre('save', async function (next) {
//   if (!this.isModified('password')) return next();
//   const salt = await bcrypt.genSalt(10);
//   this.password = await bcrypt.hash(this.password, salt);
//   next();
// });

// // Method to compare passwords
// NdrfEmployeeSchema.methods.matchPassword = async function (enteredPassword) {
//   return await bcrypt.compare(enteredPassword, this.password);
// };

const NdrfEmployee = mongoose.model('NdrfEmployee', NdrfEmployeeSchema);

function generateToken(id) {
  return jwt.sign({ id }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: process.env.REFRESH_TOKEN_EXPIRY,
  });
}

//ndrfMiddleware
const ndrfAuth = async(req,res,next) => {
  const userId = req.cookies?.accessToken;

if(!userId){
    return res.status(400).json({message: "No token found Login again"});
}

const decodedToken = jwt.verify(userId,process.env.ACCESS_TOKEN_SECRET)
const user = await NdrfEmployee.findById(decodedToken?.id).select("-password");

if(!user){
    console.log(user)
    return res.status(400).json({message: "Token is not valid"})
}

req.user = user;

next();
}

// Controller
const loginNdrfUser = async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Input fields are empty' });
  }

  const existedUser = await NdrfEmployee.findOne({ username });
  if (!existedUser) {
    return res.status(400).json({ message: 'User does not exist by this username' });
  }

//   const isPasswordValid = await existedUser.matchPassword(password);

  if (!(existedUser.password === password)) {
    return res.status(400).json({ message: 'Password is incorrect' });
  }

  const options = {
    httpOnly: true,
    secure: false, // Set to true in production with HTTPS
    maxAge: 24 * 60 * 60 * 1000,
  };

  const accessToken = generateToken(existedUser._id);

  const loggedInUser = await NdrfEmployee.findById(existedUser._id).select("-password")

  return res
    .status(200)
    .cookie('accessToken', accessToken, options)
    .json({ message: 'Logged in successfully', accessToken,  loggedInUser});
};

const getProfile = async(req,res) => {
  try {
    const user = req.user;

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      message: "User profile fetched successfully",
      user,
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    return res.status(500).json({ message: "Server error while fetching profile" });
  }
}

const logout = async(req,res) => {
  const options = {
        httpOnly: true,
        secure: true,
    };

    return res
        .status(200)
        .clearCookie("accessToken", options)
        .json({message: "LoggedOut Successfully"});
}


const routes = Router();
routes.route('/org-login').post(loginNdrfUser);
routes.route('/profile').post(ndrfAuth,getProfile)
routes.route('/logout').get(logout);

export default routes;