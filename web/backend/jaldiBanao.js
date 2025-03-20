import mongoose from "mongoose";
import { Router } from "express";
import data from "./dataUtils.js";
import moment from "moment-timezone";
import axios from "axios";

const router = Router();

let count = 0;

let interval = null;

const UpdateData = async (io) => {
  if (count < data.length) {
    const currentData = data[count];
    const enhancedData = {
      ...currentData, // Spread the current data
      createdAt: moment().tz("Asia/Kolkata").format("YYYY-MM-DDTHH:mm:ss"), // Format the date
    };
    const elasticResponse = await axios.post(
      "http://localhost:5000/search/add-post",
      {
        post_id: enhancedData.post_id || "",
        post_title: enhancedData.post_title || "",
        post_body: enhancedData.post_body || "",
        post_body_full: enhancedData.post_body_full || "",
        date: enhancedData.createdAt || "",
        likes: enhancedData.likes || 0,
        retweets: enhancedData.retweets || 0,
        post_image_url: enhancedData.post_image_url || "",
        location: enhancedData.location || "",
        url: enhancedData.url || "",
        disaster_type: enhancedData.disaster_type || "",
        source: enhancedData.source || "",
      }
    );

    io.emit("updateRealTimeData", enhancedData);
    console.log(
      `Sending data for post_id: ${enhancedData.post_id}, ${elasticResponse}`
    );
    count++;
  } else {
    console.log("All data sent.");
    clearInterval(interval);
    interval = null;
  }
};

const DataLlmCollection = mongoose.model("DataLlm",mongoose.Schema({
post_id : String,
oneLinerInfo: {type: String}
},{timestamps:true}));

const fetchDataById = async (id) => {
  console.log(id)
  const config = {
    headers: { "Content-Type": "application/json" },
  };

  const response = await axios.post(
    "http://localhost:5000/search/find-by-id",
    { id },
    config
  );
  return response.data;
};

// Utility function to generate one-liner
const generateOneLiner = async (data) => {
  const config = {
    headers: { "Content-Type": "application/json" },
  };

  const response = await axios.post(
    "http://localhost:5000/gemini/get-one-liner",
    { data },
    config
  );
  return response.data;
};


// HandleTweeter handler
const HandleTweeter = async (req, res) => {
  const {
    post_id,
    post_title,
    post_body,
    post_body_full,
    date,
    likes,
    retweets,
    post_image_url,
    location,
    url,
    disaster_type,
    source,
  } = req.body;

  const data = {post_id,post_title,post_body,post_body_full,date,likes,retweets,post_image_url,location,url,disaster_type,source}

    try {
    // Check if the data already exists
    const counter = await fetchDataById(post_id);
    if (counter.count === 0) {
      // Add data to ElasticSearch
      const elasticResponse = await axios.post("http://localhost:5000/search/add-post", {
        post_id: post_id || "",
        post_title: post_title || "",
        post_body: post_body || "",
        post_body_full: post_body_full || "",
        date: date || "",
        likes: likes || 0,
        retweets: retweets || 0,
        post_image_url: post_image_url || "",
        location: location || "",
        url: url || "",
        disaster_type: disaster_type || "",
        source: source || "",
      });

      console.log(`ElasticSearch response for post_id: ${post_id}`, elasticResponse.data);

      // Generate a one-liner from LLM
      const llmOutput = await generateOneLiner(data);
      console.log("LLM Response:", llmOutput);

      if (!llmOutput || !llmOutput["one-liner"]) {
        console.error("Error: Failed to generate one-liner");
        return res.status(400).json({ message: "Failed to generate one-liner." });
      }

      console.log("One-liner generated:", llmOutput.oneLiner);

      // Save the new data to the database
      const newData = new DataLlmCollection({
        post_id,
        oneLinerInfo: llmOutput.oneLiner,
      });
      await newData.save();

      return res.status(200).json({
        message: "Data added successfully.",
        oneLiner: llmOutput.oneLiner,
      });
    } else {
      console.log("Data already exists.");
      return res.status(400).json({ message: "Data already exists.", newData });
    }
  } catch (error) {
    console.error("Internal server error:", error.message);
    return res.status(500).json({ message: "Internal server error." });
  }
};

const HandleRss = async(req,res) => {
const {
    post_id,
    post_title,
    post_body,
    post_body_full,
    date,
    likes,
    retweets,
    post_image_url,
    location,
    url,
    disaster_type,
    source,
  } = req.body;

  const data = {post_id,post_title,post_body,post_body_full,date,likes,retweets,post_image_url,location,url,disaster_type,source}

    try {
    // Check if the data already exists
    const counter = await fetchDataById(post_id);
    if (counter.count === 0) {
      // Add data to ElasticSearch
      const elasticResponse = await axios.post("http://localhost:5000/search/add-post", {
        post_id: post_id || "",
        post_title: post_title || "",
        post_body: post_body || "",
        post_body_full: post_body_full || "",
        date: date || "",
        likes: likes || 0,
        retweets: retweets || 0,
        post_image_url: post_image_url || "",
        location: location || "",
        url: url || "",
        disaster_type: disaster_type || "",
        source: source || "",
      });

      console.log(`ElasticSearch response for post_id: ${post_id}`, elasticResponse.data);

      // Generate a one-liner from LLM
      const llmOutput = await generateOneLiner(data);
      console.log("LLM Response:", llmOutput);

      if (!llmOutput || !llmOutput["one-liner"]) {
        console.error("Error: Failed to generate one-liner");
        return res.status(400).json({ message: "Failed to generate one-liner." });
      }

      console.log("One-liner generated:", llmOutput.oneLiner);

      // Save the new data to the database
      const newData = new DataLlmCollection({
        post_id,
        oneLinerInfo: llmOutput.oneLiner,
      });
      await newData.save();

      return res.status(200).json({
        message: "Data added successfully.",
        oneLiner: llmOutput.oneLiner,
      });
    } else {
      console.log("Data already exists.");
      return res.status(400).json({ message: "Data already exists.", newData });
    }
  } catch (error) {
    console.error("Internal server error:", error.message);
    return res.status(500).json({ message: "Internal server error." });
  }
}

const generateDailyReport = async (req, res) => {
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));
  try {
    const data = await DataLlmCollection.find({
      createdAt: { $gte: startOfDay, $lt: endOfDay },
    }).sort({ createdAt: "desc"})

    const config = {
    headers: { "Content-Type": "application/json" },
  };

    const response = await axios.post("http://localhost:5000/gemini/dailyreport", {data},config)
    console.log(response.data)
    return res.status(200).json(response.data);
  } catch (error) {
    console.error("Internal server error:", error.message);
    return res.status(500).json({ message: "Internal server error." });
    
  }
}

const generateTimeLineofRandomReport = async (req, res) => {
    const { startDate, endDate } = req.body;
    const start = new Date(startDate);
    const end = new Date(endDate);
  try {
    const data = await DataLlmCollection.find({
      createdAt: { $gte: start, $lt: end },
    }).sort({ createdAt: "desc"})

    const config = {
    headers: { "Content-Type": "application/json" },
  };

    const response = await axios.post("http://localhost:5000/gemini/dailyreport", {data},config)
    console.log(response.data)
    return res.status(200).json(response.data);
  } catch (error) {
    console.error("Internal server error:", error.message);
    return res.status(500).json({ message: "Internal server error." });
    
  }
}

///v1/jaldibanao/updatedata
router.route("/updatedata").post((req, res) => {
  const io = req.app.get("io");
  if (!interval) {
    count = 0;
    interval = setInterval(() => UpdateData(io), 15000);
    res.status(200).json({ message: "Real-time data updates started." });
  } else {
    res
      .status(400)
      .json({ message: "Real-time data updates are already running." });
  }
});

///v1/jaldibanao/handle
router.route("/handle").post(HandleTweeter)
///v1/jaldibanao/handlerss
router.route("/handlerss").post(HandleRss)
router.route("/dailyreport").get(generateDailyReport)
router.route("/timeline").post(generateTimeLineofRandomReport)
export default router;
