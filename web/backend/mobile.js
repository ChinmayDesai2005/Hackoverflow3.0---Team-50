import mongoose from "mongoose";
import jwt from "jsonwebtoken";
import nodemailer from "nodemailer";
import { Router } from "express";
import admin from "firebase-admin";
import axios from "axios";
import Twilio from "twilio";
import moment from "moment-timezone";
import haversine from "haversine-distance";

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const client = Twilio(accountSid, authToken);

// Send Push Notification
const serviceAccountJSON = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountJSON),
});

//models
const Citizen = mongoose.model(
  "Citizen",
  mongoose.Schema(
    {
      name: { type: String, required: true },
      email: { type: String, required: true, unique: true },
    },
    { timestamps: true }
  )
);

const AppUsers = mongoose.model(
  "AppUser",
  mongoose.Schema(
    {
      email: { type: String, required: true, unique: true },
      name: { type: String, required: true },
      mobileNo: { type: String, required: true, unique: true },
      state: { type: String, required: true },
      gender: { type: String, required: true },
      aadharNo: { type: String, required: true },
      fcmToken: { type: String },
    },
    { timestamps: true }
  )
);

const Issue = mongoose.model(
  "Issue",
  mongoose.Schema(
    {
      photo: { type: String, default: "" },
      title: { type: String, trim: true, default: "Untitled Issue" },
      description: {
        type: String,
        trim: true,
        default: "No description provided.",
      },
      emergencyType: {
        type: String,
        enum: [
          "Natural Disaster",
          "Medical",
          "Fire",
          "Infrastructure",
          "Other",
        ],
        default: "Other",
      },
      location: { type: String, trim: true },
      userId: { type: String, required: true },
      currentStatus: {
        type: String,
        enum: ["Rejected", "Pending", "Resolved"],
        default: "Pending",
      },
      comment: { type: String, default: "" },
    },
    {
      timestamps: true,
    }
  )
);

const Sos = mongoose.model(
  "Sos",
  mongoose.Schema(
    {
      name: { type: String, required: true, default: "" },
      email: { type: String, required: true, default: "" },
      mobileNo: { type: String, required: true, default: "" },
      location: { type: String, trim: true, required: true, default: "" },
      verified: { type: Boolean, default: false },
      state: { type: String, trim: "" },
      address: { type: String, trim: "" },
      city: { type: String, trim: "" },
      district: { type: String, trim: "" },
      postcode: { type: String, trim: "" },
      emergencyType: {
        type: String,
        enum: [
          "Natural Disaster",
          "Medical",
          "Fire",
          "Infrastructure",
          "Other",
        ],
        default: "Other",
      },
      code: { type: String, enum: ["none", "red"], default: "none" },
    },
    {
      timestamps: true,
    }
  )
);

const verifiedPostSchema = new mongoose.Schema(
  {
    title: String,
    body: String,
    location: String,
    date: String,
    type: String,
    source: String,
    imageUrl: String,
    postId: String,
    priority: String,
    likes: { type: Number, default: 0 },
    dislikes: { type: Number, default: 0 },
  },
  { timestamps: true }
);

const ElasticAnalytics = new mongoose.model("ElasticAnalytics", 
  mongoose.Schema({
    totalUnverifiedPosts: { type: Number, default: 0 },
    totalPostsFromX: { type: Number, default: 0 },
    totalPostsFromRss: { type: Number, default: 0 },
    totalPostsFromApp: { type: Number, default: 0 },
    createdAt: { type: Date, unique: true },
    updatedAt: { type: Date },
  })
)

// Function to increment likes
verifiedPostSchema.methods.incrementLikes = async function () {
  this.likes += 1;
  await this.save();
};

// Function to increment dislikes
verifiedPostSchema.methods.incrementDislikes = async function () {
  this.dislikes += 1;
  await this.save();
};

// Function to update post
verifiedPostSchema.statics.updatePost = async function (postId, updatedData) {
  return await this.findOneAndUpdate(
    { postId },
    { $set: updatedData },
    { new: true }
  );
};

const VerifiedPosts = mongoose.model("Post", verifiedPostSchema);

//setup
function generateToken(id) {
  return jwt.sign({ id }, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: process.env.MOBILE_REFRESH_TOKEN_EXPIRY,
  });
}

// const transporter = nodemailer.createTransport({
//     host: 'smtp.rediffmail.com',
//     port: 465, // Use 465 for SSL, 587 for TLS
//     secure: true, // Set to true for SSL (port 465), false for TLS (port 587)
//     auth: {
//         user: process.env.RediffMail_id, // Replace with your Rediffmail email
//         pass: process.env.RediffMail_pass, // Replace with your Rediffmail password
//   },
// });

// const otpStore = new Map();

const CONFIG = {
  POST_API_URL:
    "https://eve.idfy.com/v3/tasks/async/verify_with_source/aadhaar_lite", //POST req costs 3 creds
  GET_API_URL: "https://eve.idfy.com/v3/tasks", //GET doesnt cost but requires req_id generated from POST
  TASK_ID: "74f4c926-250c-43ca-9c53-453e87ceacd1", //redundant id can be used for all reqs ... no need to changes
  GROUP_ID: "8e16424a-58fc-4ba4-ab20-5bc8e7c3c41e", // No need to change
  MAX_ATTEMPTS: 10,
  RETRY_DELAY: 5000,
};

async function reverseGeolocation(latitude, longitude) {
  const config = {
    POST_API_URL:
      "https://eve.idfy.com/v3/tasks/async/generate/reverse_geocode", // POST req costs 3 creds
    GET_API_URL: "https://eve.idfy.com/v3/tasks", // GET doesn't cost but requires req_id from POST
    task_id: "74f4c926-250c-43ca-9c53-453e87ceacd1",
    group_id: "8e16424a-58fc-4ba4-ab20-5bc8e7c3c41e",
    MAX_ATTEMPTS: 10, // Maximum attempts to poll the GET API
    POLLING_INTERVAL: 3000, // 3 seconds between attempts
  };

  try {
    const axiosInstance = axios.create({
      headers: {
        "api-key": process.env.API_KEY,
        "account-id": process.env.ACC_ID,
        "Content-Type": "application/json",
      },
      timeout: 30000,
    });
    // Step 1: POST request to initiate reverse geocoding
    const postResponse = await axiosInstance.post(config.POST_API_URL, {
      task_id: config.task_id,
      group_id: config.group_id,
      data: { latitude: latitude.trim(), longitude: longitude.trim() },
    });

    if (!postResponse.data || !postResponse.data.request_id) {
      console.error("No request ID returned from POST API.");
      return null;
    }

    const requestId = postResponse.data.request_id;

    //    Step 2: Poll the GET API until the status is 'completed' or max attempts are reached
    for (let attempt = 0; attempt < config.MAX_ATTEMPTS; attempt++) {
      await new Promise((resolve) =>
        setTimeout(resolve, config.POLLING_INTERVAL)
      );

      const getResponse = await axiosInstance.get(
        `${config.GET_API_URL}?request_id=${requestId}`
      );
      const getResponseData = getResponse.data[0];

      if (getResponseData && getResponseData.status === "completed") {
        const result = getResponseData.result?.source_output;
        if (result?.status === "location_found") {
          // Step 3: Extract required fields
          const formatted_address = result.formatted_address;

          return {
            state: formatted_address?.state || "N/A",
            city: formatted_address?.city || "N/A",
            address: result?.address || "N/A",
            district: formatted_address?.state_district || "N/A",
            postcode: formatted_address?.postcode || "N/A", // Optional if API supports postcode
          };
        } else {
          console.error("Location not found in response.");
          return null;
        }
      } else if (getResponseData.status === "failed") {
        console.error("Reverse geolocation task failed.");
        return null;
      }
    }

    console.error("Max polling attempts reached without result.");
    return "";
  } catch (error) {
    console.error("Error in reverseGeolocation:", error.message);
    return "";
  }
}

//aadhar app logics
async function verifyAadhaar(aadharNo) {
  if (!aadharNo || aadharNo.length !== 12) {
    throw new Error("Invalid Aadhaar number. ");
  }

  try {
    const axiosInstance = axios.create({
      headers: {
        "api-key": process.env.API_KEY,
        "account-id": process.env.ACC_ID,
        "Content-Type": "application/json",
      },
      timeout: 30000,
    });

    const postResponse = await axiosInstance.post(CONFIG.POST_API_URL, {
      task_id: CONFIG.TASK_ID,
      group_id: CONFIG.GROUP_ID,
      data: { aadhaar_number: aadharNo },
    });

    const requestId = postResponse.data.request_id;
    let verificationResult;

    let attempts = 0;

    while (attempts < CONFIG.MAX_ATTEMPTS) {
      attempts++;
      const getResponse = await axiosInstance.get(
        `${CONFIG.GET_API_URL}?request_id=${requestId}`
      );
      verificationResult = getResponse.data[0];

      if (
        verificationResult.status === "completed" ||
        verificationResult.status === "failed"
      )
        break;

      await new Promise((resolve) => setTimeout(resolve, CONFIG.RETRY_DELAY));
    }

    const isVerified =
      verificationResult?.result?.source_output?.status === "id_found";

    return {
      verified: isVerified,
      details: verificationResult?.result?.source_output || {},
      requestId,
      status: verificationResult?.status,
      fullResult: verificationResult,
    };
  } catch (error) {
    throw new Error(`Verification process failed: ${error.message}`);
  }
}

async function verifyMobile(NAME, mobileNo) {
  const config = {
    POST_API_URL:
      "https://eve.idfy.com/v3/tasks/async/verify_with_source/ind_mobile_number", // POST req costs 3 creds
    GET_API_URL: "https://eve.idfy.com/v3/tasks", // GET doesn't cost but requires req_id from POST
    task_id: "74f4c926-250c-43ca-9c53-453e87ceacd1",
    group_id: "8e16424a-58fc-4ba4-ab20-5bc8e7c3c41e",
    MAX_ATTEMPTS: 10, // Maximum attempts to poll the GET API
    POLLING_INTERVAL: 3000, // 3 seconds between attempts
  };

  try {
    const axiosInstance = axios.create({
      headers: {
        "api-key": process.env.API_KEY,
        "Content-Type": "application/json",
        "account-id": process.env.ACC_ID,
      },
      timeout: 30000,
    });

    // Step 1: Initiate the verification process with a POST request
    const postResponse = await axiosInstance.post(config.POST_API_URL, {
      task_id: config.task_id,
      group_id: config.group_id,
      data: { mobile_number: mobileNo },
    });

    if (!postResponse.data || !postResponse.data.request_id) {
      console.error("No request ID returned from POST API.");
      return false;
    }

    const requestId = postResponse.data.request_id;

    // Step 2: Poll the GET API for verification status
    for (let attempt = 0; attempt < config.MAX_ATTEMPTS; attempt++) {
      await new Promise((resolve) =>
        setTimeout(resolve, config.POLLING_INTERVAL)
      ); // Wait before next attempt

      const getResponse = await axiosInstance.get(
        `${config.GET_API_URL}?request_id=${requestId}`
      );
      const getResponseData = getResponse.data[0];
      if (getResponseData && getResponseData.status === "completed") {
        // Check if the name matches
        const mobileNumberDetails =
          getResponseData.result?.source_output?.mobile_number_details;
        if (mobileNumberDetails && mobileNumberDetails.name) {
          const responseNameParts = mobileNumberDetails.name
            .toLowerCase()
            .split(/\s+/);
          const providedNameParts = NAME.toLowerCase().split(/\s+/);

          const isNameMatched = providedNameParts.some((part) =>
            responseNameParts.includes(part)
          );

          return isNameMatched;
        } else {
          console.error(
            "No name found in verification response. Details:",
            mobileNumberDetails
          );
          return false;
        }
      } else if (getResponseData.status === "failed") {
        console.error("Verification task failed.");
        return false;
      }
    }

    console.error("Max polling attempts reached without result.");
    return false;
  } catch (error) {
    console.error("Error in verifyMobile:", error.message);
    return false;
  }
}

//controllers
//aadhar based auth controllers
const registerAadhar = async (req, res) => {
  const { email, name, mobileNo, aadharNo, fcmToken } = req.body;
  try {
    const isNameMatched = await verifyMobile(name, mobileNo);
    if (!isNameMatched) {
      return res.status(400).json({
        message:
          "Name verification failed. Please ensure the name matches the registered mobile number and aadhar number.",
      });
    }

    const result = await verifyAadhaar(aadharNo);
    console.log("Info: Final verification result", {
      verified: result.verified,
    });

    if (result.verified === false) {
      return res.status(400).json({ message: "Aadhar No is incorrect" });
    }

    const user = await AppUsers.create({
      name,
      email,
      mobileNo,
      state: result?.details?.state || " ",
      gender: result?.details?.gender || " ",
      aadharNo,
      fcmToken,
    });

    if (!user) {
      return res.status(400).json({ message: "User not created. Try Again!!" });
    }

    const createdUser = await AppUsers.findById(user._id).select("-aadharNo");

    const accessToken = generateToken(createdUser._id);
    return res.status(200).json({
      message: "User Registered Successfully",
      createdUser,
      accessToken,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Cannot Login with Aadhar", error });
  }
};

const loginAadhar = async (req, res) => {
  const { mobileNo, fcmToken } = req.body;

  try {
    if (!mobileNo) {
      return res
        .status(400)
        .json({ message: "Both Fields are required to be saved" });
    }

    const existedUser = await AppUsers.findOne({ mobileNo });
    if (!existedUser) {
      return res
        .status(400)
        .json({ message: "No user with the Mobile No found" });
    }

    if (existedUser.fcmToken !== fcmToken) {
      await AppUsers.updateOne(
        { _id: existedUser._id },
        { $set: { fcmToken } }
      );
    }

    const createdUser = await AppUsers.findById(existedUser._id).select(
      "-aadharNo"
    );

    const accessToken = generateToken(createdUser._id);

    return res.status(200).json({
      message: "User Logged In successfully",
      createdUser,
      accessToken,
    });
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Cannot Login with Aadhar", error });
  }
};
//auth controllers
// const citizenRegister = async(req,res) =>{
//     const {email} = req.body;

//     try {
//         const existingUser = await Citizen.findOne({ email });

//         if (existingUser) {
//             return res.status(400).json({ message: "User already registered with this mobile number" });
//         }

//         const otp = Math.floor(100000 + Math.random() * 900000).toString();
//         otpStore.set(email, otp);

//         await transporter.sendMail({
//             from: process.env.RediffMail_id,
//             to: email,
//             subject: 'OTP for Registration',
//             text: `Your OTP is: ${otp}`,
//         });

//         res.status(200).json({ message: "OTP sent successfully" });
//     } catch (error) {
//         console.error("Error sending OTP:", error);
//         res.status(500).json({ message: "Failed to send OTP", error });
//     }
// }

// const verifyRegisteredUser = async(req,res) => {
//     const { email, otp, name } = req.body;
// try {
//         if (!email || !name || !otp) {
//             return res.status(400).json({ message: "All fields are required" });
//         }

//         if (otpStore.has(email) && otpStore.get(email) === otp) {
//             const user = await Citizen.create({ email, name });

//             const createdUser = await Citizen.findById(user._id);

//             if (!createdUser) {
//                 return res.status(400).json({ message: "User creation failed" });
//             }

//             const accessToken = generateToken(createdUser._id);

//             otpStore.delete(email);

//             return res.status(200).json({ message: "User registered successfully", createdUser, accessToken });
//         } else {
//             return res.status(400).json({ message: "Invalid OTP or OTP has expired" });
//         }
//     } catch (error) {
//         console.error("Error during OTP verification:", error);
//         return res.status(500).json({ message: "An error occurred during OTP verification", error });
//     }
// }

// const citizenLogin= async(req,res) => {
// const {email} = req.body;

//     try {
//         if(!email){
//             return res.status(400).json({message: "Email Field are empty"})
//         }

//         const existedUser = await Citizen.findOne({email})

//         if(!existedUser){
//             return res.status(400).json({message: "User does not exist by this username/email"})
//         }

//         const otp = Math.floor(100000 + Math.random() * 900000).toString();
//         otpStore.set(email, otp);

//         await transporter.sendMail({
//             from: process.env.RediffMail_id,
//             to: email,
//             subject: 'OTP for Registration',
//             text: `Your OTP is: ${otp}`,
//         });

//         res.status(200).json({ message: "OTP sent successfully" });
//     } catch (error) {
//         console.error("Error sending OTP:", error);
//         res.status(500).json({ message: "Failed to send OTP", error });
//     }

// }

// const verifyLoggedInUser = async (req,res) => {
//     const {email,otp} = req.body;

//     try {
//         if (!email || !otp) {
//             return res.status(400).json({ message: "All fields are required" });
//         }

//         if (otpStore.has(email) && otpStore.get(email) === otp) {

//             const loggedInUser = await Citizen.findOne({email});

//             if (!loggedInUser) {
//                 return res.status(400).json({ message: "User not found" });
//             }

//             const accessToken = generateToken(loggedInUser._id);

//             otpStore.delete(email);

//             return res.status(200).json({ message: "User loggedin successfully", loggedInUser, accessToken });
//         } else {
//             return res.status(400).json({ message: "Invalid OTP or OTP has expired" });
//         }
//     } catch (error) {
//         console.error("Error during OTP verification:", error);
//         return res.status(500).json({ message: "An error occurred during OTP verification", error });
//     }
// }

const AddIssue = async (req, res) => {
  const { photo, title, description, emergencyType, location, userId } =
    req.body;

  const newIssue = await Issue.create({
    photo,
    title,
    description,
    emergencyType,
    location,
    userId,
  });

  if (!newIssue) {
    return res.status(400).json({ message: "New Issue not raised" });
  }

  const date = newIssue.createdAt;
  const formattedDate = date.toLocaleDateString("en-GB");

  const data = {
    post_title: newIssue.title || "",
    post_body: newIssue.description || "",
    date: formattedDate || "",
    likes: 0,
    retweets: 0,
    post_image_url: "",
    post_image_b64: newIssue.photo || "",
    location: newIssue.location || "",
    url: "",
    disaster_type: newIssue.emergencyType || "",
  };

  const elasticResponse = await axios.post(
    "http://localhost:5000/search/add-post",
    {
      post_id: newIssue._id || "",
      post_title: newIssue.title || "",
      post_body: newIssue.description || "",
      date: date || "",
      likes: 0,
      retweets: 0,
      post_image_url: "",
      post_image_b64: newIssue.photo || "",
      location: newIssue.location || "",
      url: "",
      disaster_type: newIssue.emergencyType || "",
    }
  );

  if (!elasticResponse || elasticResponse.status !== 200) {
    return res
      .status(500)
      .json({ message: "Failed to sync data with Elasticsearch." });
  }

  return res
    .status(200)
    .json({ message: "Issue raised successfully", newIssue });
};

const getPersonalIssue = async (req, res) => {
  try {
    const { userId } = req.body;
    const personalIssues = await Issue.find({ userId });

    if (!personalIssues) {
      return res.status(404).json({ message: "No issues found" });
    }

    return res
      .status(200)
      .json({ message: "Your Issues Fetched", personalIssues });
  } catch (error) {
    console.log("Error in getting personal issue", error);
    return res.status(200).json({ message: "Error in loading data" });
  }
};

const getAllIssue = async (req, res) => {
  const allIssue = await Issue.find({});

  if (allIssue.length === 0) {
    return res.status(404).json({ message: "There are no issues to retrieve" });
  }

  return res.status(200).json(allIssue);
};

const Radius = 2000;
const SosThreshold = 10;
let activeLocation = { location: null, count: 0 };
const sendSos = async (req, res) => {
  const { name, email, location, emergencyType, mobileNo } = req.body;

  if (!name || !email) {
    return res.status(400).json({ message: "Login again" });
  }

  if (!location || !emergencyType) {
    return res.status(400).json({ message: "Give location permission" });
  }

  const [latStr, longStr] = location.split(",");
  const response = await reverseGeolocation(latStr, longStr);

  // Check if an SOS exists with the same mobileNo
  const existingSos = await Sos.findOne({ mobileNo });

  if (existingSos) {
    // Delete the existing SOS
    await Sos.findByIdAndDelete(existingSos._id);
    console.log(`Deleted existing SOS with ID: ${existingSos._id}`);
  }

  const newSos = await Sos.create({
    name,
    email,
    mobileNo,
    location,
    emergencyType,
    code: "none",
    state: response.state,
    address: response.address,
    city: response.city,
    district: response.district,
    postcode: response.postcode,
  });

  if (!newSos) {
    return res.status(400).json({ message: "Sos not raised" });
  }

  const [lat, long] = location.split(",").map(Number);
  if (activeLocation.location) {
    // Calculate distance between active location and current location
    const activeLatLong = activeLocation.location.split(" ").map(Number);
    const activeLatLongObj = { lat: activeLatLong[0], lng: activeLatLong[1] };
    const currentLatLongObj = { lat, lng: long };
    const distance = haversine(activeLatLongObj, currentLatLongObj);
    console.log(distance);

    if (distance <= Radius) {
      activeLocation.count += 1;

      if (activeLocation.count > SosThreshold) {
        await Sos.findByIdAndUpdate(newSos._id, { code: "red" }, { new: true });
      }
    } else {
      activeLocation = { location: `${lat} ${long}`, count: 1 };
    }
  } else {
    activeLocation = { location: `${lat} ${long}`, count: 1 };
  }

  const io = req.app.get("io");
  io.emit("newSos", {
    id: newSos._id,
    name: newSos.name,
    location: newSos.location,
    emergencyType: newSos.emergencyType,
    createdAt: newSos.createdAt,
    code: newSos.code,
    state: newSos.state,
    address: newSos.address,
    city: newSos.city,
    district: newSos.district,
    postcode: newSos.postcode,
  })

  const createdSos = await Sos.findById(newSos._id);

  return res.status(200).json({ message: "Sos sent", createdSos });
};

const getSos = async (req, res) => {
  try {
    const allSos = await Sos.find({}).lean();

    if (allSos.length === 0) {
      return res
        .status(404)
        .json({ message: "There are no issues to retrieve" });
    }

    const sosWithISTTime = allSos.map((sos) => ({
      ...sos,
      createdAt: moment(sos.createdAt)
        .tz("Asia/Kolkata")
        .format("YYYY-MM-DDTHH:mm:ss"),
    }));

    return res.status(200).json(sosWithISTTime);
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server Error", error: err.message });
  }
};
const perHrSosCount = async (req, res) => {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const hourlyData = [];

    for (let hour = 0; hour < 24; hour++) {
      const startHour = new Date(startOfDay);
      startHour.setHours(hour);

      const endHour = new Date(startHour);
      endHour.setHours(hour + 1);

      const sosCount = await Sos.countDocuments({
        createdAt: {
          $gte: startHour,
          $lt: endHour,
        },
      });

      hourlyData.push({
        hour: `${hour.toString().padStart(2, "0")}:00-${(hour + 1)
          .toString()
          .padStart(2, "0")}:00`,
        count: sosCount,
      });
    }

    return res.status(200).json(hourlyData);
  } catch (error) {
    console.error("Error in perHrSosCount:", error);
    return res.status(500).json({
      message: "Error fetching hourly SOS counts",
      error: error.message,
    });
  }
};

const perMonthSosCount = async (req, res) => {
  try {
    const currentYear = new Date().getFullYear();
    const monthlyData = [];

    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    for (let month = 0; month < 12; month++) {
      const startOfMonth = new Date(currentYear, month, 1);
      const endOfMonth = new Date(currentYear, month + 1, 1);

      const sosCount = await Sos.countDocuments({
        createdAt: {
          $gte: startOfMonth,
          $lt: endOfMonth,
        },
      });

      // const dailyData = [];
      // for (let day = 1; day <= new Date(currentYear, month + 1, 0).getDate(); day++) {
      //     const startOfDay = new Date(currentYear, month, day);
      //     const endOfDay = new Date(currentYear, month, day + 1);

      //     const dailyCount = await Sos.countDocuments({
      //         createdAt: {
      //             $gte: startOfDay,
      //             $lt: endOfDay
      //         }
      //     });

      //     dailyData.push({
      //         date: `${currentYear}-${month + 1}-${day}`,
      //         count: dailyCount
      //     });
      // }

      monthlyData.push({
        month: monthNames[month],
        year: currentYear,
        totalMonthlyCount: sosCount,
        // dailyCounts: dailyData
      });
    }

    return res.status(200).json(monthlyData);
  } catch (error) {
    console.error("Error in perMonthSosCount:", error);
    return res.status(500).json({
      message: "Error fetching monthly SOS counts",
      error: error.message,
    });
  }
};

const verifySos = async (req, res) => {
  try {
    const emergencyNumbers = {
      "Natural Disaster": ["9321604801"],
      Medical: ["7045649922"],
      Fire: ["9137166421"],
      Infrastructure: ["9321604801"],
      Other: ["9321604801"],
    };
    const { id } = req.body;
    if (!id) {
      return res.status(400).json({ message: "ID is required" });
    }

    const sos = await Sos.findById(id);
    if (!sos) {
      return res.status(404).json({ message: "SOS record not found" });
    }

    sos.verified = !sos.verified;
    await sos.save();
    const emergencyType = sos.emergencyType;
    const numberToSend = emergencyNumbers[emergencyType];
    var message = `Alert!! There is an emergency at the location ${sos.location}`;
    console.log({ numberToSend });

    await sendSMS(message, numberToSend);

    res.status(200).json({
      message: "Verified status updated successfully",
      data: sos,
    });
  } catch (error) {
    res.status(500).json({
      message: "An error occurred while updating verified status",
      error: error.message,
    });
  }
};

const warningNotification = async (req, res) => {
  try {
    const { title, description } = req.body;
    if (!title || !description) {
      return res.status(400).json({
        error: "Missing required fields",
        required: ["title", "description"],
      });
    }
    const users = await AppUsers.find({}, { fcmToken: 1 });

    const fcmTokens = users.map((user) => user.fcmToken).filter(Boolean);

    if (fcmTokens.length === 0) {
      return res.status(404).json({ error: "No valid FCM tokens found." });
    }

    const message = {
      notification: {
        title,
        body: description,
      },
    };

    const results = [];
    for (const token of fcmTokens) {
      try {
        const response = await admin.messaging().send({ ...message, token });
        results.push({ token, status: "success", messageId: response });
      } catch (error) {
        results.push({ token, status: "failure", error: error.message });
        console.error(
          `Failed to send notification to ${token}:`,
          error.message
        );
      }
    }

    // Return the results
    return res.status(200).json({
      message: "Notifications processed",
      results,
    });
  } catch (error) {
    console.error("Error sending notifications:", error);
    return res.status(500).json({
      error: "Failed to send notifications",
      details: error.message,
    });
  }
};

const sosCounter = async (req, res) => {
  try {
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));

    const sosVerifiedCount = await Sos.countDocuments({
      verified: false,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    });

    const sosResolvedCount = await Sos.countDocuments({
      verified: true,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    });

    return res.status(200).json({
      unVerifiedCount: sosVerifiedCount,
      resolvedCount: sosResolvedCount,
    });
  } catch (error) {
    console.log("Error in connecting to the route", error);
  }
};

const formatTime = (totalSeconds) => {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = Math.floor(totalSeconds % 60);
  return `${hours}h ${minutes}m ${seconds}s`;
};

const sosAverageTurnaroundTime = async (req, res) => {
  try {
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));

    // Calculate daily average turnaround time
    const averageDailyTurnaroundTime = await Sos.aggregate([
      {
        $match: {
          verified: true,
          createdAt: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $project: {
          timeDiff: {
            $subtract: ["$updatedAt", "$createdAt"],
          },
        },
      },
      {
        $group: {
          _id: null,
          averageTime: { $avg: "$timeDiff" },
        },
      },
    ]);

    // Calculate overall average turnaround time
    const overallTurnAroundTime = await Sos.aggregate([
      {
        $match: {
          verified: true,
        },
      },
      {
        $project: {
          timeDiff: {
            $subtract: ["$updatedAt", "$createdAt"],
          },
        },
      },
      {
        $group: {
          _id: null,
          averageTime: { $avg: "$timeDiff" },
        },
      },
    ]);

    // Handle cases where no posts are found
    const averageTimeInSeconds = averageDailyTurnaroundTime.length
      ? averageDailyTurnaroundTime[0].averageTime / 1000
      : 0;

    const overallAverageTimeInSec = overallTurnAroundTime.length
      ? overallTurnAroundTime[0].averageTime / 1000
      : 0;

    // Format the time
    const averageTimeFormatted = formatTime(averageTimeInSeconds);
    const overallAverageTimeFormatted = formatTime(overallAverageTimeInSec);

    res.status(200).json({
      message: "Average turnaround time fetched successfully",
      averageTimeFormatted,
      overallAverageTimeFormatted,
    });
  } catch (error) {
    console.error(error);
    return res.status(400).json({
      message: "Error in getting SOS average response time",
    });
  }
};

const FAST2SMS_API_KEY = process.env.FAST2SMS_API;
//sms function
const sendSMS = async (message, numbers) => {
  if (!numbers || numbers.length === 0) {
    console.error("No phone numbers provided.");
    return;
  }

  // Preprocess numbers to ensure they include '+91'
  const formattedNumbers = numbers.map((number) => {
    // Add '+91' if it doesn't already have it
    return number.startsWith("+91") ? number : `+91${number}`;
  });

  try {
    // Send SMS for each number
    for (const number of formattedNumbers) {
      await client.messages
        .create({
          body: message,
          messagingServiceSid: process.env.TWILIO_SERVICE_SID,
          to: number,
        })
        .then((message) =>
          console.log(`Message sent to ${number}: ${message.sid}`)
        );
    }
  } catch (error) {
    console.error("Error sending SMS:", error.message || error);
    throw error;
  }

  // const url = "https://www.fast2sms.com/dev/bulkV2";
  // const payload = {
  //   message: message,
  //   language: "english",
  //   route: "q", // Transactional route
  //   numbers: numbers?.join(','), // Comma-separated mobile numbers
  // };

  // try {
  //   const response = await axios.post(url, payload, {
  //     headers: {
  //       authorization: FAST2SMS_API_KEY,
  //       "Content-Type": "application/json",
  //     },
  //   });
  //   console.log("SMS sent successfully:", response.data);
  //   return response.data;
  // } catch (error) {
  //   console.log(error);
  //   console.error("Error sending SMS:", error.response?.data || error.message);
  //   throw error;
  // }
};

const smsTesting = async (req, res) => {
  try {
    const { title, description, state } = req.body;

    if (!title || !description) {
      return res
        .status(400)
        .json({ error: "Title and description are required" });
    }

    const message = `${title}: ${description}`;
    let citizens;
    // Fetch all phone numbers from the Citizen database
    if (!state || state.trim() === "") {
      // No state provided, fetch all users
      citizens = await AppUsers.find({});
    } else {
      // State provided, fetch users from that state
      citizens = await AppUsers.find({ state });
    }
    const phoneNumbers = citizens.map((citizen) => citizen.mobileNo);

    if (phoneNumbers.length === 0) {
      return res
        .status(404)
        .json({ error: "No phone numbers found in the database" });
    }

    // Send SMS
    const result = await sendSMS(message, phoneNumbers);
    res.status(200).json({ message: "SMS sent successfully", result });
  } catch (error) {
    res
      .status(500)
      .json({ error: "Failed to send SMS", details: error.message });
  }
};

//verified posts
const addVerifiedPost = async (req, res) => {
  const {
    title,
    body,
    location,
    date,
    type,
    source,
    imageUrl,
    postId,
    priority,
  } = req.body;
  try {
    const verified = new VerifiedPosts({
      title,
      body,
      location,
      date,
      type,
      source,
      imageUrl,
      postId,
      priority,
    });
    const response = await Issue.findByIdAndUpdate(
      postId,
      { currentStatus: "Resolved" },
      { new: true }
    );

    if (!response) {
      return res.status(404).json({ message: "No issue found" });
    }

    await verified.save();
    res.status(201).json({ success: true, verified });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: "Server Error" });
  }
};

const getVerifiedPost = async (req, res) => {
  try {
    const verified = await VerifiedPosts.find();
    res.status(200).json({ success: true, verified });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: "Server Error" });
  }
};
const increaseLike = async (req, res) => {
  try {
    const { postId } = req.body;
    const post = await VerifiedPosts.findOneAndUpdate(
      { postId },
      { $inc: { likes: 1 } },
      { new: true }
    );

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.status(200).json({ message: "Like added", post });
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error", error });
  }
};

// Increase Dislikes
const increaseDislike = async (req, res) => {
  try {
    const { postId } = req.body;
    const post = await VerifiedPosts.findOneAndUpdate(
      { postId },
      { $inc: { dislikes: 1 } },
      { new: true }
    );

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.status(200).json({ message: "Dislike added", post });
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error", error });
  }
};

// Update Post
const updatePost = async (req, res) => {
  try {
    const { postId, updatedData } = req.body;

    const post = await VerifiedPosts.findOneAndUpdate(
      { postId },
      { $set: updatedData },
      { new: true }
    );

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.status(200).json({ message: "Post updated", post });
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error", error });
  }
};

const getTotalCountVerifiedPosts = async (req, res) => {
  try {
    const verifiedPostCount = await VerifiedPosts.countDocuments({
      _id: { $exists: true },
    });

    const sources = ["Twitter", "RSS", "AapdaMitra App", "Others"];
    const sourceCount = await Promise.all(
      sources.map(async (source) => {
        const count = await VerifiedPosts.countDocuments({ source });
        return { source, count };
      })
    );
    return res.status(200).json({
      message: "Total count fetched and source differene",
      verifiedPostCount,
      sourceCount,
    });
  } catch (error) {
    console.log("Error in getting total counts", error);
    return res.status(500).json({ message: "Error in getting total count" });
  }
};

const RejectedVerifiedPosts = async (req, res) => {
  const {
    title,
    body,
    location,
    date,
    type,
    source,
    imageUrl,
    postId,
    comment,
    priority,
  } = req.body;
  try {
    const response = await Issue.findByIdAndUpdate(
      postId,
      { currentStatus: "Rejected", comment: comment },
      { new: true }
    );

    if (!response) {
      return res.status(404).json({ message: "No issue found" });
    }

    res.status(201).json({ message: "Issue rejected successfully", response });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: "Server Error" });
  }
};

//sos analytics
const getSosAnalytics = async (req, res) => {
  const today = new Date();
  const startOfDay = new Date(today.setHours(0, 0, 0, 0));
  const endOfDay = new Date(today.setHours(23, 59, 59, 999));

  try {
    const matchStage = {
      $match: {
        createdAt: {
          $gte: startOfDay,
          $lte: endOfDay,
        },
      },
    };

    const groupStages = {
      postcode: {
        $group: {
          _id: "$postcode",
          count: { $sum: 1 },
          avgResolutionTime: {
            $avg: { $subtract: ["$updatedAt", "$createdAt"] },
          },
        },
      },
      city: {
        $group: {
          _id: "$city",
          count: { $sum: 1 },
          avgResolutionTime: {
            $avg: {
              $subtract: ["$updatedAt", "$createdAt"],
            },
          },
        },
      },
      state: {
        $group: {
          _id: "$state",
          count: { $sum: 1 },
          avgResolutionTime: {
            $avg: {
              $subtract: ["$updatedAt", "$createdAt"],
            },
          },
        },
      },
      district: {
        $group: {
          _id: { state: "$state", district: "$district" },
          count: { $sum: 1 },
          avgResolutionTime: {
            $avg: {
              $subtract: ["$updatedAt", "$createdAt"],
            },
          },
        },
      },
    };

    //daily analysis
    const postcodeAnalytics = await Sos.aggregate([
      matchStage,
      groupStages.postcode,
    ]);
    const cityAnalytics = await Sos.aggregate([matchStage, groupStages.city]);
    const stateAnalytics = await Sos.aggregate([matchStage, groupStages.state]);
    const districtAnalytics = await Sos.aggregate([
      matchStage,
      groupStages.district,
    ]);

    return res
      .status(200)
      .json({
        postcodeAnalytics,
        cityAnalytics,
        stateAnalytics,
        districtAnalytics,
      });
  } catch (error) {
    console.log("Error in extracting the sos information", error);
    return res.status(400).json({ message: "Error in connecting the Sos" });
  }
};

//Heavy analytics dashabord
const getAnalytics = async (req, res) => {
  try {
    const today = new Date();
    const last7Days = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const last30Days = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

    //trends
    const getTrends = async (Model, matchQuery, dateField = "createdAt") => {
      return await Model.aggregate([
        { $match: matchQuery },
        {
          $group: {
            _id: {
              $dateToString: { format: "%Y-%m-%d", date: `$${dateField}` },
            },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]);
    };

    const overallSosLast7Days = await Sos.countDocuments({
      createdAt: { $gte: last7Days },
    });
    const overallSosLast30Days = await Sos.countDocuments({
      createdAt: { $gte: last30Days },
    });
    const unresolvedSosCount = await Sos.countDocuments({ resolved: false });

    const overallIssuesLast7Days = await Issue.countDocuments({
      createdAt: { $gte: last7Days },
    });
    const overallIssuesLast30Days = await Issue.countDocuments({
      createdAt: { $gte: last30Days },
    });
    const unresolvedIssuesCount = await Issue.countDocuments({
      resolved: false,
    });

    const sosTrendsLast30Days = await getTrends(Sos, {
      createdAt: { $gte: last30Days },
    });
    const issueTrendsLast30Days = await getTrends(Issue, {
      createdAt: { $gte: last30Days },
    });

    const avgSosResolutionTime = await Sos.aggregate([
      { $match: { resolved: true } },
      {
        $project: {
          resolutionTime: { $subtract: ["$updatedAt", "$createdAt"] },
        },
      },
      { $group: { _id: null, avgResolutionTime: { $avg: "$resolutionTime" } } },
    ]);

    // Regional Analytics
    const sosByRegion = await Sos.aggregate([
      {
        $group: {
          _id: "$location",
          totalSos: { $sum: 1 },
          unresolvedSos: {
            $sum: { $cond: [{ $eq: ["$resolved", false] }, 1, 0] },
          },
          last7Days: {
            $sum: {
              $cond: [{ $gte: ["$createdAt", last7Days] }, 1, 0],
            },
          },
          last30Days: {
            $sum: {
              $cond: [{ $gte: ["$createdAt", last30Days] }, 1, 0],
            },
          },
          emergencyTypeDistribution: { $push: "$emergencyType" },
        },
      },
    ]);

    const issuesByRegion = await Issue.aggregate([
      {
        $group: {
          _id: "$location",
          totalIssues: { $sum: 1 },
          unresolvedIssues: {
            $sum: { $cond: [{ $eq: ["$resolved", false] }, 1, 0] },
          },
          last7Days: {
            $sum: {
              $cond: [{ $gte: ["$createdAt", last7Days] }, 1, 0],
            },
          },
          last30Days: {
            $sum: {
              $cond: [{ $gte: ["$createdAt", last30Days] }, 1, 0],
            },
          },
          issueTypeDistribution: { $push: "$issueType" },
        },
      },
    ]);

    const regionalAnalytics = sosByRegion.map((sosData) => {
      const location = sosData._id;
      const issueData = issuesByRegion.find(
        (issue) => issue._id === location
      ) || {
        totalIssues: 0,
        unresolvedIssues: 0,
        last7Days: 0,
        last30Days: 0,
        issueTypeDistribution: [],
      };

      return {
        location,
        sos: {
          total: sosData.totalSos,
          unresolved: sosData.unresolvedSos,
          last7Days: sosData.last7Days,
          last30Days: sosData.last30Days,
          emergencyTypeDistribution: sosData.emergencyTypeDistribution.reduce(
            (acc, type) => {
              acc[type] = (acc[type] || 0) + 1;
              return acc;
            },
            {}
          ),
        },
        issues: {
          total: issueData.totalIssues,
          unresolved: issueData.unresolvedIssues,
          last7Days: issueData.last7Days,
          last30Days: issueData.last30Days,
          issueTypeDistribution: issueData.issueTypeDistribution.reduce(
            (acc, type) => {
              acc[type] = (acc[type] || 0) + 1;
              return acc;
            },
            {}
          ),
        },
      };
    });

    return res.status(200).json({
      overall: {
        sos: {
          totalLast7Days: overallSosLast7Days,
          totalLast30Days: overallSosLast30Days,
          unresolved: unresolvedSosCount,
          trendsLast30Days: sosTrendsLast30Days,
          avgResolutionTime: avgSosResolutionTime[0]?.avgResolutionTime || 0,
        },
        issues: {
          totalLast7Days: overallIssuesLast7Days,
          totalLast30Days: overallIssuesLast30Days,
          unresolved: unresolvedIssuesCount,
          trendsLast30Days: issueTrendsLast30Days,
        },
      },
      regional: regionalAnalytics,
    });
  } catch (error) {
    console.error(error);
    return res.status(400).json({ message: "Error in getting analytics" });
  }
};


const addElasticAnalytics = async (req, res) => {
  const { totalPostsFromX = 0, totalPostsFromRss = 0 } = req.body;
  const totalPostsFromApp = await Issue.countDocuments();
  const totalUnverifiedPosts = totalPostsFromX + totalPostsFromRss + totalPostsFromApp;

  try {
    const date = moment.tz("Asia/Kolkata").format('YYYY-MM-DD');

    const dataExists = await ElasticAnalytics.findOne({ createdAt: date });

    if (dataExists) {
      const updatedAnalytics = await ElasticAnalytics.findByIdAndUpdate(
        dataExists._id,
        {
          totalPostsFromX: dataExists.totalPostsFromX + totalPostsFromX,
          totalPostsFromRss: dataExists.totalPostsFromRss + totalPostsFromRss,
          totalPostsFromApp: totalPostsFromApp !== dataExists.totalPostsFromApp
            ? totalPostsFromApp
            : dataExists.totalPostsFromApp + (totalPostsFromApp - dataExists.totalPostsFromApp),
          updatedAt: date,
        },
        { new: true }
      );

      updatedAnalytics.totalUnverifiedPosts =
        updatedAnalytics.totalPostsFromX +
        updatedAnalytics.totalPostsFromRss +
        updatedAnalytics.totalPostsFromApp;

      await updatedAnalytics.save();

      return res.status(200).json({
        message: "Analytics updated successfully",
        updatedAnalytics,
      });
    } else {
      const analytics = await ElasticAnalytics.create({
        totalUnverifiedPosts,
        totalPostsFromX,
        totalPostsFromRss,
        totalPostsFromApp,
        createdAt: date,
        updatedAt: date,
      });
      return res.status(200).json({ message: "Analytics created successfully", analytics });
    }
  } catch (error) {
    console.log("Error in adding analytics", error);
    return res.status(500).json({ message: "Error in adding analytics", error });
  }
};



const getFinalReportData = async (req, res) => {
  const { startDate, endDate } = req.body;
  const start = new Date(startDate);
  const end = new Date(endDate);

  try {
    const getSourcesData = await ElasticAnalytics.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
        },
      },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$createdAt" }, 
          },
          totalPostsFromX: { $sum: "$totalPostsFromX" },
          totalPostsFromRss: { $sum: "$totalPostsFromRss" },
          totalPostsFromApp: { $sum: "$totalPostsFromApp" },
          totalUnverifiedPosts: { $sum: "$totalUnverifiedPosts" },
        },
      },
      {
        $sort: { _id: 1 }, 
      },
    ]);

    if (getSourcesData.length === 0) {
      return res.status(200).json({ message: "No data found for the given date range." });
    }

    const sosData = await Sos.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
        },
      },
      {
        $group: {
          _id: {
            $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
          },
          verifiedSos: { $sum: { $cond: [{ $eq: ["$verified", true] }, 1, 0] } },
          unverifiedSos: { $sum: { $cond: [{ $eq: ["$verified", false] }, 1, 0] } },
        },
      },
      {
        $sort: { _id: 1 },
      },
    ])

    const VerifiedPostCount = await VerifiedPosts.aggregate([
  {
    $match: {
      createdAt: { $gte: start, $lte: end },
    },
  },
  {
    $group: {
      _id: {
        $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
      },
      VerifiedDoc: { $sum: 1 },
    },
  },
  {
    $sort: { _id: 1 },
  },
]);

const UnverifiedCount = await ElasticAnalytics.aggregate([
  {
    $group: {
      _id: {
        $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
      },
      totalUnverifiedPosts: { $sum: "$totalUnverifiedPosts" },
    },
  },
  {
    $sort: { _id: 1 }, // Sort by date in ascending order
  },
]);

    return res.status(200).json({
      message: "Final report data retrieved successfully",
      data: getSourcesData, 
      sosData: sosData,
      verifiedPostData: VerifiedPostCount,
      UnverifiedPostData: UnverifiedCount
    });
  } catch (error) {
    console.log("Error in getting final report", error);
    return res.status(500).json({ message: "Error in getting final report" });
  }
};


const AnalyticsDb = new mongoose.model("AnalyticsDb", 
  mongoose.Schema({
    location: {type: String, required: true},
    totalSos: {type: Number, required: true},
  },{timestamps: true})
)

const postIssuesMapData = async (req, res) => {
  const {location,totalSos} = req.body;
try {
  const dataExists = await AnalyticsDb.findOne({ location: location });

    if (dataExists) {
      const updatedAnalytics = await AnalyticsDb.findByIdAndUpdate(
        dataExists._id,
        {
          totalSos: dataExists.totalSos + totalSos
        },
        { new: true }
      );

      await updatedAnalytics.save();

      return res.status(200).json({
        message: "Analytics updated successfully",
        updatedAnalytics,
      });
    } else {
      const analytics = await AnalyticsDb.create({
        location,
        totalSos
      });
      return res.status(200).json({ message: "Analytics created successfully", analytics });
}} catch (error) {
  console.log("Error in getting map data", error);
  return res.status(200).json({message: "Error in loading message"})
}
}

const getIssuesMapData = async(req,res)=>{
try {
  const getSourcesData = await AnalyticsDb.aggregate([
      {
        $group: {
          _id: "$location", // Group by location
          location: { $first: "$location" }, // Include the location in the result
          totalSos: { $sum: "$totalSos" }, // Sum the totalSos for each location
        },
      },
      {
        $sort: { _id: 1 }, 
      },
    ]);

    if (getSourcesData.length === 0) {
      return res.status(200).json({ message: "No data found for the given date range." });
    }

    return res.status(200).json({message: "Message sos data sent", getSourcesData})
} catch (error) {
  console.log("Error in getting", error);
  return res.status(400).json({message: "Error"})
}
}


//raise a req controller

//routes
import { getFundraiser } from "./controllers/donation.controller.js";
const routes = Router();

routes.route("/verify-aadhar").post(registerAadhar);
routes.route("/login-with-aadhar").post(loginAadhar);
// routes.route('/register-citizen').post(citizenRegister)
// routes.route('/verify-reg-citizen').post(verifyRegisteredUser)
// routes.route('/login-mobile').post(citizenLogin)
// routes.route('/verify-login-citizen').post(verifyLoggedInUser)
routes.route("/get-fundraisers").get(getFundraiser);
routes.route("/add-issue").post(AddIssue);
routes.route("/send-sos").post(sendSos);
routes.route("/get-personal-issue").post(getPersonalIssue);
routes.route("/get-all-elastic").post(addElasticAnalytics);
routes.route("/get-all-report-data").post(getFinalReportData);

//verified posts
routes.route("/add-post").post(addVerifiedPost);
routes.route("/get-all-post").get(getVerifiedPost);
routes.route("/like-post").post(increaseLike);
routes.route("/dislike-post").post(increaseDislike);
routes.route("/update-post").post(updatePost);
routes.route("/post-map-location-data").post(postIssuesMapData);
routes.route("/get-map-location-data").get(getIssuesMapData);

//for admin routes
routes.route("/sos-count").get(sosCounter);
routes.route("/sos-average-time").get(sosAverageTurnaroundTime);
routes.route("/get-all-issue").get(getAllIssue);
routes.route("/get-all-sos").get(getSos);
routes.route("/per-hr-sos").get(perHrSosCount);
routes.route("/per-month-sos").get(perMonthSosCount);
routes.route("/verify-sos").post(verifySos);
routes.route("/send-notification").post(warningNotification);
routes.route("/send-message").post(smsTesting);
routes.route("/get-verified-data").get(getTotalCountVerifiedPosts);
routes.route("/get-analytics").get(getAnalytics);
routes.route("/reject-issue").post(RejectedVerifiedPosts);
routes.route("/get-sos-detailed-sos").get(getSosAnalytics);

export default routes;
