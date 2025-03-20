import React, { useRef, useState } from "react";
import "./Searchbar.css";
// import MainLogo from "../../assets/main_logo.svg";
import { IoGridOutline } from "react-icons/io5";
import { IoGrid } from "react-icons/io5";
import Button from "react-bootstrap/Button";
import { FaThList } from "react-icons/fa";
// import $ from "jquery";

function Searchbar() {
  const [query, setQuery] = useState("");
  const [location, setLocation] = useState("");
  const [date, setDate] = useState("");
  const [disaster, setDisaster] = useState("");
  const [priority, setPriority] = useState("");
  const [view, setView] = useState("grid");
  const [isNLP, setIsNLP] = useState(true);
  const [responseObjects, setResponseObjects] = useState([]);
  const mainSearchBar = useRef(null);

  const handleAutocomplete = async (e) => {
    console.log(e.target.value);

    try {
      const response = await fetch(
        "http://localhost:5000/search/autocomplete?query=" + e.target.value
      );
      if (!response.ok) {
        throw new Error(`Response status: ${response.status}`);
      }

      const json = await response.json();
      const data = json.aggregations.auto_complete.buckets;
      const _ = [];

      data.forEach((item) => _.push(item));
      console.log(_);
      $("#main-search-bar").autocomplete({
        source: _,
      });
    } catch (error) {
      console.error(error.message);
    }
  };

  const handleSubmit = async () => {
    const request = {
      query: query,
      location: location,
      date: date,
      disaster: disaster,
      priority: priority,
    };
    console.log(request);

    const endpoint = "http://localhost:5000/search/elastic";

    try {
      let formData = new FormData();
      formData.append("query", query);
      if (location) {
        formData.append("location", location);
      }
      if (date) {
        formData.append("date", date);
      }
      if (disaster) {
        formData.append("disaster", disaster);
      }
      if (priority) {
        formData.append("priority", priority);
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
      // setResponseCounts(newResponseCounts);
    } catch (error) {
      toast.error("Something went wrong. Try again later.");
      console.error(error.message);
    }
  };

  return (
    <>
      <div className="searchbar-container">
        <div className="searchbar-wrapper">
          <input
            placeholder="Search"
            ref={mainSearchBar}
            id="main-search-bar"
            className="searchbar-input"
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <select
          className="searchbar-select location"
          onChange={(e) => setLocation(e.target.value)}
        >
          <option value="">Set Location</option>
          <option value="volvo">Volvo</option>
          <option value="saab">Saab</option>
          <option value="mercedes">Mercedes</option>
          <option value="audi">Audi</option>
        </select>
        <input
          type="date"
          className="searchbar-select"
          onChange={(e) => setDate(e.target.value)}
        />
        <select
          className="searchbar-select"
          onChange={(e) => setDisaster(e.target.value)}
        >
          <option value="">Disaster Type</option>
          <option value="volvo">Volvo</option>
          <option value="saab">Saab</option>
          <option value="mercedes">Mercedes</option>
          <option value="audi">Audi</option>
        </select>
        <select
          className="searchbar-select"
          onChange={(e) => setPriority(e.target.value)}
        >
          <option value="">Set Priority</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>

        <div className="searchbar-view-select">
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
        </div>

        <div className="searchbar-submit" onClick={handleSubmit}>
          <button>Search</button>
        </div>
      </div>
      {responseObjects && (
        <div className="response">
          {responseObjects.map((index) => (
            <div>{index["post_body"]}</div>
          ))}
        </div>
      )}
    </>
  );
}

export default Searchbar;
