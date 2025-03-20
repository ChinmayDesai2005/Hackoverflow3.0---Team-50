import React from "react";
import { useRef, useState } from "react";
import Header from "../../components/header/header";
// import Footer from "../../components/footer/Footer";
import Searchbar from "../../components/searchbar/searchbar";
import "./ElasticSearch.css";
import EventCard from "../../components/eventCard/EventCard";
import MainLogo from "../../assets/MainLogo.png";
import { IoGridOutline } from "react-icons/io5";
import { IoGrid } from "react-icons/io5";
import Button from "react-bootstrap/Button";
import { FaThList } from "react-icons/fa";
// import $ from "jquery";
import { Badge, Spinner, Tab, Tabs } from "react-bootstrap";
import CardContainer from "../../components/cardContainer/cardContainer";
import { Link } from "react-router-dom";
import axios from "axios";
import ReactMarkdown from "react-markdown";
import rehypeRaw from "rehype-raw";

const ElasticSearch = () => {
  const [query, setQuery] = useState("");
  const [location, setLocation] = useState("");
  const [date, setDate] = useState("");
  const [disaster, setDisaster] = useState("");
  const [priority, setPriority] = useState("");
  const [source, setSource] = useState("");
  const [view, setView] = useState("grid");
  const [isNLP, setIsNLP] = useState(true);
  const [responseObjects, setResponseObjects] = useState([]);
  const [selectedPosts, setSelectedPosts] = useState({});
  const [selectedPostsLength, setSelectedPostsLength] = useState(0);
  const responseRef = useRef(null);
  const [newsSummary, setNewsSummary] = useState("Initial");
  const mainSearchBar = useRef(null);
  const summaryRef = useRef(null);

  //   const handleAutocomplete = async (e) => {
  //     console.log(e.target.value);

  //     try {
  //       const response = await fetch(
  //         "http://localhost:5000/search/autocomplete?query=" + e.target.value
  //       );
  //       if (!response.ok) {
  //         throw new Error(Response status: ${response.status});
  //       }

  //       const json = await response.json();
  //       const data = json.aggregations.auto_complete.buckets;
  //       const _ = [];

  //       data.htmlForEach((item) => _.push(item));
  //       console.log(_);
  //       $("#main-search-bar").autocomplete({
  //         source: _,
  //       });
  //     } catch (error) {
  //       console.error(error.message);
  //     }
  //   };

  const handlePostSelect = (e, idx, response) => {
    try {
      // console.log(e.target.checked, idx, response);
      var tempObj = selectedPosts;
      if (e.target.checked) {
        tempObj[idx] = response;
        setSelectedPosts(tempObj);
        setSelectedPostsLength((prev) => prev + 1);
      } else {
        var tempObj = selectedPosts;
        delete tempObj[idx];
        setSelectedPosts(tempObj);
        setSelectedPostsLength((prev) => prev - 1);
      }

      console.log(selectedPostsLength);
      console.log(selectedPosts);
      console.log(Object.keys(selectedPosts).length);
    } catch (error) {
      console.error(error.message);
    }
  };

  const clearCheckboxes = () => {
    if (responseRef.current) {
      for (var i = 0; i < responseRef.current.children.length; i++) {
        responseRef.current.children[i].children[0].children[0].checked = false;
      }
    }
  };

  const generateNewsSummary = async (data) => {
    const newsData = data;
    const summarizeNewsURL = "http://127.0.0.1:5000/gemini/summarize-news";
    try {
      const response = await axios({
        method: "post",
        url: summarizeNewsURL,
        headers: { "Access-Control-Allow-Origin": "*" },
        data: { newsData },
      });
      console.log(response);
      setNewsSummary(response.data["summary"]);
    } catch (error) {
      console.log(error);
    }
  };

  const handleSubmit = async () => {
    const request = {
      query: query,
      location: location,
      date: date,
      disaster: disaster,
      priority: priority,
      source: source,
      nlp: isNLP,
    };
    console.log(request);

    setSelectedPosts({});
    setNewsSummary("");
    // clearCheckboxes();

    const endpoint = "http://localhost:5000/search/elastic";

    try {
      let formData = new FormData();
      formData.append("query", query);
      formData.append("nlp", isNLP);
      if (!isNLP) {
        formData.append("nlp", isNLP);
        if (location) {
          formData.append("location", location);
        }
        if (date) {
          formData.append("date", date);
        }
        if (disaster) {
          formData.append("disaster_type", disaster);
        }
        if (priority) {
          formData.append("priority", priority);
        }
        if (source) {
          formData.append("source", source);
        }
      }

      const response = await fetch(endpoint, {
        method: "POST",
        body: formData,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "*",
        },
      });

      const responseData = await response.json();

      console.log(responseData);
      setResponseObjects(responseData);
      // const onlyRSS = responseData["results"].filter(
      //   (item) => item["source"] === "RSS"
      // );
      // console.log(onlyRSS);
      if (responseData.results.length > 0) {
        await generateNewsSummary(responseData);
      }
      //   console.log(responseObjects);
      // setResponseCounts(newResponseCounts);
    } catch (error) {
      //   toast.error("Something went wrong. Try again later.");
      console.error(error.message);
    }
  };

  const resetIndexes = (posts) => {
    const newPosts = [];
    const onlyValues = Objects.values(posts);
    console.log(onlyValues);
    return onlyValues;
  };

  const printSummary = () => {
    if (summaryRef.current) {
      const printContents = summaryRef.current.innerHTML;
      const originalContents = document.body.innerHTML;

      document.body.innerHTML = `
        <div style="white-space: pre-wrap; font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; text-align: center;">
          <img src=${MainLogo} alt="Logo" style="width: 60%; height: 20%; margin-bottom: 10px;" />
          <h3 style="border-bottom: 2px solid #ccc; padding-bottom: 10px;">News Summary</h3>
          <div style="text-align: left; margin-top: 20px;">
            ${printContents}
          </div>
        </div>
      `;

      window.print();

      // Restore the original page content
      document.body.innerHTML = originalContents;
      // Reload the page to restore event listeners and React functionality
      window.location.reload();
    }
  };

  return (
    <div>
      <Header />
      <div className="searchbar-container">
        <div className="searchbar-wrapper">
          <input
            placeholder="Search"
            ref={mainSearchBar}
            id="main-search-bar"
            className="searchbar-input"
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                handleSubmit();
              }
            }}
            onChange={(e) => setQuery(e.target.value)}
          />
          <div className="searchbar-submit" onClick={handleSubmit}>
            <button>Search</button>
          </div>
        </div>
        <div className="nlp-driven-wrapper">
          <input
            type="checkbox"
            name="nlp-driven"
            defaultChecked={true}
            onChange={(e) => {
              setIsNLP(e.target.checked);
            }}
          />
          <label htmlFor="nlp-driven"> NLP-driven query</label>
          <br />
        </div>

        {!isNLP && (
          <div className="searchbar-parameters">
            <div className="searchbar-parameter">
              <label htmlFor="location"> Location</label>
              <select
                className="searchbar-select location"
                name="location"
                onChange={(e) => setLocation(e.target.value)}
              >
                <option value="" selected>
                  Select Location
                </option>
                <option value="Andhra Pradesh">Andhra Pradesh</option>
                <option value="Arunachal Pradesh">Arunachal Pradesh</option>
                <option value="Assam">Assam</option>
                <option value="Bihar">Bihar</option>
                <option value="Chhattisgarh">Chhattisgarh</option>
                <option value="Delhi">Delhi</option>
                <option value="Goa">Goa</option>
                <option value="Gujarat">Gujarat</option>
                <option value="Haryana">Haryana</option>
                <option value="Himachal Pradesh">Himachal Pradesh</option>
                <option value="Jammu and Kashmir">Jammu and Kashmir</option>
                <option value="Jharkhand">Jharkhand</option>
                <option value="Karnataka">Karnataka</option>
                <option value="Kerala">Kerala</option>
                <option value="Madhya Pradesh">Madhya Pradesh</option>
                <option value="Maharashtra">Maharashtra</option>
                <option value="Odisha">Odisha</option>
                <option value="Punjab">Punjab</option>
                <option value="Rajasthan">Rajasthan</option>
                <option value="Tamil Nadu">Tamil Nadu</option>
                <option value="Telangana">Telangana</option>
                <option value="Uttar Pradesh">Uttar Pradesh</option>
                <option value="Uttarakhand">Uttarakhand</option>
                <option value="West Bengal">West Bengal</option>
                <option value="Visakhapatnam">Visakhapatnam</option>
                <option value="Vijayawada">Vijayawada</option>
                <option value="Tirupati">Tirupati</option>

                <option value="Itanagar">Itanagar</option>

                <option value="Guwahati">Guwahati</option>
                <option value="Dibrugarh">Dibrugarh</option>

                <option value="Patna">Patna</option>
                <option value="Gaya">Gaya</option>

                <option value="Raipur">Raipur</option>
                <option value="Bilaspur">Bilaspur</option>

                <option value="New Delhi">New Delhi</option>
                <option value="Old Delhi">Old Delhi</option>

                <option value="Panaji">Panaji</option>
                <option value="Margao">Margao</option>

                <option value="Ahmedabad">Ahmedabad</option>
                <option value="Surat">Surat</option>
                <option value="Vadodara">Vadodara</option>

                <option value="Gurugram">Gurugram</option>
                <option value="Faridabad">Faridabad</option>

                <option value="Shimla">Shimla</option>
                <option value="Manali">Manali</option>

                <option value="Srinagar">Srinagar</option>
                <option value="Jammu">Jammu</option>

                <option value="Ranchi">Ranchi</option>
                <option value="Jamshedpur">Jamshedpur</option>

                <option value="Bengaluru">Bengaluru</option>
                <option value="Mysuru">Mysuru</option>

                <option value="Thiruvananthapuram">Thiruvananthapuram</option>
                <option value="Kochi">Kochi</option>

                <option value="Bhopal">Bhopal</option>
                <option value="Indore">Indore</option>

                <option value="Mumbai">Mumbai</option>
                <option value="Pune">Pune</option>
                <option value="Nagpur">Nagpur</option>

                <option value="Bhubaneswar">Bhubaneswar</option>
                <option value="Cuttack">Cuttack</option>

                <option value="Amritsar">Amritsar</option>
                <option value="Ludhiana">Ludhiana</option>

                <option value="Jaipur">Jaipur</option>
                <option value="Jodhpur">Jodhpur</option>
                <option value="Udaipur">Udaipur</option>

                <option value="Chennai">Chennai</option>
                <option value="Coimbatore">Coimbatore</option>
                <option value="Madurai">Madurai</option>

                <option value="Hyderabad">Hyderabad</option>
                <option value="Warangal">Warangal</option>

                <option value="Lucknow">Lucknow</option>
                <option value="Kanpur">Kanpur</option>
                <option value="Varanasi">Varanasi</option>

                <option value="Dehradun">Dehradun</option>
                <option value="Nainital">Nainital</option>

                <option value="Kolkata">Kolkata</option>
                <option value="Darjeeling">Darjeeling</option>
              </select>
            </div>
            <div className="searchbar-parameter">
              <label htmlFor="date"> Date</label>
              <input
                type="date"
                className="searchbar-select"
                name="date"
                onChange={(e) => setDate(e.target.value)}
              />
            </div>
            <div className="searchbar-parameter">
              <label htmlFor="disaster-type"> Disaster Type</label>
              <select
                className="searchbar-select"
                name="disaster-type"
                onChange={(e) => setDisaster(e.target.value)}
              >
                <option value="" disabled selected>
                  Select Disaster Type
                </option>
                <option value="Earthquake">Earthquake</option>
                <option value="Flood">Flood</option>
                <option value="Cyclone">Cyclone</option>
                <option value="Tsunami">Tsunami</option>
                <option value="Drought">Drought</option>
                <option value="Landslide">Landslide</option>
                <option value="Volcanic Eruption">Volcanic Eruption</option>
                <option value="Hurricane">Hurricane</option>
                <option value="Tornado">Tornado</option>
                <option value="Forest Fire">Forest Fire</option>
                <option value="Heatwave">Heatwave</option>
                <option value="Avalanche">Avalanche</option>

                <option value="Industrial Accident">Industrial Accident</option>
                <option value="Nuclear Disaster">Nuclear Disaster</option>
                <option value="Chemical Spill">Chemical Spill</option>
                <option value="Building Collapse">Building Collapse</option>
                <option value="Fire">Fire</option>
                <option value="Power Outage">Power Outage</option>
                <option value="Transportation Accident">
                  Transportation Accident
                </option>
                <option value="Bridge Collapse">Bridge Collapse</option>

                <option value="Pandemic">Pandemic</option>
                <option value="Epidemic">Epidemic</option>
                <option value="Medical Emergency">Medical Emergency</option>
                <option value="Food Contamination">Food Contamination</option>

                <option value="Terrorist Attack">Terrorist Attack</option>
                <option value="Bomb Threat">Bomb Threat</option>
                <option value="Active Shooter">Active Shooter</option>
                <option value="Riots">Riots</option>
                <option value="Civil Unrest">Civil Unrest</option>
                <option value="Kidnapping">Kidnapping</option>

                <option value="Oil Spill">Oil Spill</option>
                <option value="Animal Attack">Animal Attack</option>
                <option value="Invasive Species">Invasive Species</option>
                <option value="Pollution Incident">Pollution Incident</option>

                <option value="Gas Leak">Gas Leak</option>
                <option value="Structural Failure">Structural Failure</option>
                <option value="Road Blockage">Road Blockage</option>
                <option value="Rescue Operation">Rescue Operation</option>
                <option value="">None</option>
              </select>
            </div>
            <div className="searchbar-parameter">
              <label htmlFor="priority">Priority</label>
              <select
                className="searchbar-select"
                name="priority"
                onChange={(e) => setPriority(e.target.value)}
              >
                <option value="">Set Priority</option>
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
              </select>
            </div>
            <div className="searchbar-parameter">
              <label htmlFor="source">Source</label>
              <select
                className="searchbar-select"
                name="source"
                onChange={(e) => setSource(e.target.value)}
              >
                <option value="">Set Source</option>
                <option value="Twitter">Twitter</option>
                <option value="RSS">RSS</option>
                <option value="AapdaMitra App">AapdaMitra App</option>
              </select>
            </div>
          </div>
        )}

        {/* <div className="searchbar-view-select">
          {view === "grid" && (
            <>
              <IoGrid size={30} color={"var(--primary-color)"} />
              <FaThList
                size={30}
                color={"var(--light-gray)"}
                onClick={() => setView("list")}
              />
            </>
          )}
          {view === "list" && (
            <>
              <IoGrid
                size={30}
                color={"var(--light-gray)"}
                onClick={() => setView("grid")}
              />
              <FaThList size={30} color={"var(--primary-color)"} />
            </>
          )}
        </div> */}
      </div>
      {responseObjects["parameters"] &&
        Object.values(responseObjects["parameters"]).length > 0 && (
          <div className="parameters-response">
            <div className="parameters-wrapper">
              <h4>Tags extracted from query: </h4>
              <div className="parameter-tags">
                {Object.values(responseObjects["parameters"]).map(
                  (response, idx) => (
                    <Badge pill bg="dark" key={idx}>
                      {response}
                    </Badge>
                  )
                )}
              </div>
            </div>
          </div>
        )}
      <div className="document-summary-wrapper">
        <div className="result-cards">
          {responseObjects["results"] &&
            responseObjects["results"].length > 0 && (
              <h4>Results ({responseObjects["results"].length}): </h4>
            )}
          {responseObjects && responseObjects.length <= 0 && (
            <h4>Get started by searching for something.</h4>
          )}
          {responseObjects["results"] &&
          responseObjects["results"].length > 0 ? (
            <div className="response" ref={responseRef}>
              {responseObjects["results"].map((response, idx) => (
                <div className="card-wrapper">
                  <label className="checkbox-wrapper">
                    {/* <input
                      type="checkbox"
                      className="card-checkbox"
                      onChange={(e) => {
                        handlePostSelect(e, idx, response);
                      }}
                    /> */}
                  </label>
                  <EventCard key={idx} data={response} />
                </div>
              ))}
            </div>
          ) : (
            responseObjects["results"] && (
              <h4>Nothing Found. Please try with a different query.</h4>
            )
          )}
        </div>
        <div className="news-summary-final">
          <Tabs
            defaultActiveKey="summary"
            id="uncontrolled-tab-example"
            className="mb-3"
          >
            <Tab eventKey="summary" title="Summary" className="search-summary">
              {newsSummary === "" && (
                <div className="news-summary-wrapper">
                  <ReactMarkdown
                    children={"Summary is Loading. Please wait..."}
                    // className={"md-format"}
                  />
                  <Spinner animation="border" role="status">
                    <span className="visually-hidden">Loading...</span>
                  </Spinner>
                </div>
              )}
              {newsSummary !== "Initial" && newsSummary !== "" && (
                <div className="news-summary-wrapper">
                  <div ref={summaryRef} className="md-format">
                    <ReactMarkdown
                      children={newsSummary}
                      urlTransform={(value) => value}
                      rehypePlugins={[rehypeRaw]}
                    />
                  </div>
                  <Button
                    variant="primary"
                    onClick={printSummary}
                    className="mt-3"
                  >
                    Print Summary
                  </Button>
                </div>
              )}
            </Tab>
            {/* <Tab eventKey="images" title="Images" className="search-images">
              <div className="response-image-wrapper">
                {responseObjects["results"] &&
                  responseObjects["results"].length > 0 &&
                  responseObjects["results"].map((object, idx) => {
                    return <img key={idx} src={object.post_image_url} />;
                  })}
              </div>
            </Tab> */}
          </Tabs>
        </div>
      </div>

      {Object.keys(selectedPosts).length > 0 && selectedPostsLength > 0 && (
        <div className="selected-posts-wrapper">
          <div className="selected-posts">
            <div className="selected-posts-info">
              {Object.keys(selectedPosts).length} POST(S) SELECTED
            </div>
            <div className="selected-posts-buttons">
              <Link
                className="selected-posts-verify"
                to={"/verifyposts"}
                state={{
                  posts: Object.values(selectedPosts),
                }}
              >
                VERIFY
              </Link>
              <Link
                className="selected-posts-summarize"
                to={"/summarizeposts"}
                state={{
                  posts: Object.values(selectedPosts),
                }}
              >
                SUMMARIZE
              </Link>
            </div>
          </div>
        </div>
      )}
      {/* <Footer /> */}
    </div>
  );
};

export default ElasticSearch;
