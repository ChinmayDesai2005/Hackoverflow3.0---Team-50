import React, { useState } from "react";
import "./multiTabContainer.css";

const MultiTabContainer = () => {
  const [openTabs, setOpenTabs] = useState(["Social Media", "News"]);

  const socialMediaData = [
    {
      headline: "Floods in Chennai",
      title: "In south Chennai, flooding disrupts life once again",
      text: "The northeast monsoon has caused severe flooding in south Chennai, especially in areas along OMR, Kannagi Nagar, and Velachery. Some regions like Valasaravakkam experienced less waterlogging, but others, such as AGS Colony in Velachery, saw water levels rise to 2–3 feet before receding with the help of motor pumps.",
      location: "Chennai",
      date: "October 16, 2024",
      time: "11:49 am IST",
      disasterType: "Flood",
      source: "The Hindu",
      image: "https://via.placeholder.com/400x300",
    },
  ];

  const newsData = [
    {
      headline: "Cyclone Alert",
      title: "Cyclone in Bay of Bengal intensifies, impacting coastal Andhra",
      text: "A severe cyclone is forming in the Bay of Bengal, leading to warnings in Andhra Pradesh and Tamil Nadu. Authorities are preparing for emergency responses.",
      location: "Andhra Pradesh",
      date: "October 20, 2024",
      time: "8:00 am IST",
      disasterType: "Cyclone",
      source: "The Hindu",
      image: "https://via.placeholder.com/400x300",
    },
    {
      headline: "Floods in Odisha",
      title: "Odisha suffers from heavy rainfall and flooding",
      text: "Continuous rainfall in Odisha has led to massive flooding in urban and rural areas, affecting thousands of people.",
      location: "Odisha",
      date: "October 18, 2024",
      time: "9:00 am IST",
      disasterType: "Flood",
      source: "The Hindu",
      image: "https://via.placeholder.com/400x300",
    },
  ];

  const toggleTab = (tabName) => {
    if (openTabs.includes(tabName)) {
      setOpenTabs(openTabs.filter((tab) => tab !== tabName));
    } else {
      setOpenTabs([...openTabs, tabName]);
    }
  };

  const renderCard = (data) => (
    <div className="card">
      <div className="card-content">
        <div className="card-left">
          <h2 className="headline">{data.headline}</h2>
          <h3 className="title">{data.title}</h3>
          <p className="text">{data.text}</p>
        </div>
        <div className="card-center">
          <div className="info-grid">
            <div className="info-item">
              <span className="info-label">Location</span>
              <span className="info-value">{data.location}</span>
            </div>
            <div className="info-item">
              <span className="info-label">Date</span>
              <span className="info-value">{data.date}</span>
            </div>
            <div className="info-item">
              <span className="info-label">Time</span>
              <span className="info-value">{data.time}</span>
            </div>
            <div className="info-item">
              <span className="info-label">Disaster Type</span>
              <span className="info-value">{data.disasterType}</span>
            </div>
          </div>
          <div className="source">{data.source}</div>
        </div>
        <div className="card-right">
          <img src={data.image} alt={data.headline} className="card-image" />
        </div>
      </div>
    </div>
  );

  const renderContent = (tabName) => {
    const tabWidth = openTabs.length > 0 ? `${100 / openTabs.length}%` : "100%";

    return (
      <div
        key={tabName}
        className="tab-content"
        style={{
          width: tabWidth,
          height: "calc(100vh - 150px)",
          overflow: "auto",
          padding: "20px",
          backgroundColor: "#F4F7FE",
          borderRadius: "20px",
          margin: "0 10px",
        }}
      >
        <div className="cards-container">
          {tabName === "Social Media"
            ? socialMediaData.map((item, index) => (
                <div className="card-wrapper" key={index}>
                  <label className="checkbox-wrapper">
                    <input type="checkbox" className="card-checkbox" />
                  </label>
                  {renderCard(item)}
                </div>
              ))
            : newsData.map((item, index) => (
                <div className="card-wrapper" key={index}>
                  <label className="checkbox-wrapper">
                    <input type="checkbox" className="card-checkbox" />
                  </label>
                  {renderCard(item)}
                </div>
              ))}
        </div>
      </div>
    );
  };

  return (
    <div className="event-card-container">
      <div className="tabs">
        <div className="tab-wrapper">
          <button
            className={`tab ${
              openTabs.includes("Social Media") ? "active" : ""
            }`}
            onClick={() => toggleTab("Social Media")}
          >
            <span className="tab-text">Social Media</span>
            <span className="tab-icon">
              {openTabs.includes("Social Media") ? "−" : "+"}
            </span>
          </button>
          <button
            className={`tab ${openTabs.includes("News") ? "active" : ""}`}
            onClick={() => toggleTab("News")}
          >
            <span className="tab-text">News</span>
            <span className="tab-icon">
              {openTabs.includes("News") ? "−" : "+"}
            </span>
          </button>
        </div>
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: "row",
          gap: "20px",
          marginTop: "20px",
        }}
      >
        {openTabs.map((tabName) => renderContent(tabName))}
      </div>
    </div>
  );
};

export default MultiTabContainer;
