import mongoose from 'mongoose';
import Router from 'express';
import Twilio from "twilio";
import jwt from "jsonwebtoken";


const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const client = Twilio(accountSid, authToken);

function generateToken(id) {
  return jwt.sign({ id }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: process.env.MOBILE_REFRESH_TOKEN_EXPIRY,
  });
}


const mobileAdmin = await mongoose.model("MobileAdmin", new mongoose.Schema({
    name: {type: String},
    mobileNo: {type: String, required: true},
    fcmToken: {type: String, required: true},
    type: {type: String,enum: ["admin"], default: "admin"},
},{timestamps:true}));

const adminIssue = await mongoose.model("adminIssue",new mongoose.Schema({
    photo: { type: String, default: "" },
    title: { type: String, trim: true, default: "Untitled Issue" },
    description: {
        type: String,
        trim: true,
        default: "No description provided.",
      },
    userId: { type: String, required: true },
},{timestamps:true}));

//sms
const sendSMS = async (message, number) => {
  try {
    await client.messages.create({
      body: message,
      messagingServiceSid: process.env.TWILIO_SERVICE_SID,
      to: number.startsWith("+91") ? number : `+91${number}`,
    });
    console.log(`Message sent to ${number}`);
  } catch (error) {
    console.error("Error sending SMS:", error.message || error);
    throw error;
  }
};

const otpStore = new Map();


const adminLogin = async (req, res) => {
  try {
    const { mobileNo, fcmToken } = req.body;

    if (!mobileNo) {
      return res.status(400).json({ message: "Mobile number is required." });
    }

    // Check if the mobile number exists in the admin collection
    let mobileNoExist = await mobileAdmin.findOne({ mobileNo });

    if (!mobileNoExist) {
      // If not an admin, register as a new user
      mobileNoExist = new mobileAdmin({ mobileNo, fcmToken });
      await mobileNoExist.save();
      console.log("New user registered:", mobileNoExist);
    }

    // Generate a random 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store OTP in memory (expires after 5 minutes)
    otpStore.set(mobileNo, otp);
    setTimeout(() => otpStore.delete(mobileNo), 5 * 60 * 1000); // Delete OTP after 5 minutes

    // Send OTP via SMS
    await sendSMS(`Your OTP is: ${otp}`, mobileNo);

    return res.status(200).json({ message: "OTP sent successfully" });
  } catch (error) {
    console.error("Error in login:", error);
    res.status(500).json({ message: "Server Error" });
  }
};

/**
 * Verify Logged-in User
 */
const verifyLoggedInUser = async (req, res) => {
  try {
    const { mobileNo, otp, fcmToken } = req.body;

    if (!mobileNo || !otp) {
      return res.status(400).json({ message: "Mobile number and OTP are required." });
    }

    // Validate OTP
    if (otpStore.has(mobileNo) && otpStore.get(mobileNo) === otp) {
      // Retrieve user from database
      const loggedInUser = await mobileAdmin.findOne({ mobileNo });

      if (!loggedInUser) {
        return res.status(400).json({ message: "User not found." });
      }

      // Generate JWT token for the user
      const accessToken = generateToken(loggedInUser._id);

      // Update FCM token (optional: update only if provided)
      if (fcmToken) {
        loggedInUser.fcmToken = fcmToken;
        await loggedInUser.save();
      }

      // Delete OTP after successful verification
      otpStore.delete(mobileNo);

      return res.status(200).json({
        message: "User logged in successfully.",
        loggedInUser,
        accessToken,
      });
    } else {
      return res.status(400).json({ message: "Invalid OTP or OTP has expired." });
    }
  } catch (error) {
    console.error("Error during OTP verification:", error);
    return res.status(500).json({
      message: "An error occurred during OTP verification.",
      error,
    });
  }
};

const addAdminPostIssues = async (req, res) => {
  try {
    const { photo ,title, description, userId } = req.body;
    const createdIssue = await adminIssue.create({ photo, title, description, userId });
    if(!createdIssue){
      return res.status(400).json({ message: "Issue not created." });
    }

    return res.status(200).json({ message: "Issue created successfully.", createdIssue });
  } catch (error) {
    console.error("Error fetching issues:", error);
    return res.status(500).json({ message: "Server Error" });
  }
};

const getAdminPostIssue = async(req,res) =>{
  try {
    const issues = await adminIssue.find();
    if (!issues) {
      return res.status(400).json({ message: "No issues found." });
    }
    return res.status(200).json({ issues })
  } catch (error) {
    console.log('Error in fetching issues:', error);
    return res.status(500).json({ message: "Server Error" });
  }
}

const getAdminLiveLocation = async(req,res) => {
const {location, userId} = req.body;
try {
  const io = req.app.get("io");
  io.emit("liveLocation", { location, userId });

  console.log("Live location sent successfully.",location,userId);

  return res.status(200).json({ message: "Live location is being sent successfully." });
} catch (error) {
  console.log('Error in fetching live location:', error);
  return res.status(500).json({ message: "Server Error" });
}
}






const router = Router();

///v1/adminmobile prefix
router.route('/login').post(adminLogin)
router.route('/login-admin').post(verifyLoggedInUser)
router.route('/admin-add-issue').post(addAdminPostIssues)
router.route('/get-admin-issue').get(getAdminPostIssue)
router.route('/get-admin-live-location').get(getAdminLiveLocation);

export default(router);






