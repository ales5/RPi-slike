document.addEventListener("DOMContentLoaded", () => {
    const mainMenu = document.getElementById("main-menu");
    const menusContainer = document.getElementById("menus-container");
    const yearsMenu = document.getElementById("years-menu");
    const eventsMenu = document.getElementById("events-menu");
    const photosMenu = document.getElementById("photos-menu");
    const displayContainer = document.getElementById("display-container");
    const subMenuContainer = document.getElementById("submenu-container");
    // const subMenuContainer = document.createElement("div"); // Submenu container
    // subMenuContainer.id = "submenu-container";
    // menusContainer.appendChild(subMenuContainer);
    menusContainer.style.display = "flex"; // Show menus
  
    let inactivityTimeout; // Store timeout for inactivity
    let mode = undefined; // Default mode
    
    // Fetch data from server
    async function fetchData(url) {
    const response = await fetch(url);
    return response.json();
    }
    
    // Utility function to get a random subset of photos
    function getRandomSubset(array, count) {
        let random_indexes = [];
        let number_of_uniqe_indexes_found = 0;
        while (number_of_uniqe_indexes_found < count){
            let random_index = Math.floor(Math.random() * array.length);
            if (!random_indexes.includes(random_index)){
                random_indexes.push(random_index);
                number_of_uniqe_indexes_found = number_of_uniqe_indexes_found + 1;
            }
        }
        random_indexes.sort();
        return random_indexes.map(i => array[i]);
    }

    

    // Function to get a cookie value by name
    function getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }
    
    // Function to set a cookie
    function setCookie(name, value, days = 7) {
        const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toUTCString();
        document.cookie = `${name}=${JSON.stringify(value)}; expires=${expires}; path=/`;
    }
    


    // Global variable to control the display loop
    var isDisplayingPhotos_sequential = false;
    var isDisplayingPhotos_completely_random = false;
    var isDisplayingPhotos_random_selected_year = false;
    var isDisplayingPhotos_random_year = false;

    // Function to stop any running display loop
    function stopPhotoDisplay() {
        isDisplayingPhotos_sequential = false;
        isDisplayingPhotos_completely_random = false;
        isDisplayingPhotos_random_selected_year = false;
        isDisplayingPhotos_random_year = false;
    }
    

  // Display Years Menu
  async function displayYearsMenu(callback) {
    const years = await fetchData("/years");
    yearsMenu.innerHTML = "";
    years.forEach((year, index) => {
      const yearItem = document.createElement("li");
      yearItem.textContent = year;
      yearItem.addEventListener("click", () => callback(year, index));
      yearsMenu.appendChild(yearItem);
      console.log(menusContainer.style.display)
    });
  }

  // Display Events Menu
  async function displayEventsMenu(year, callback) {
    const events = await fetchData(`/events/${year}`);
    eventsMenu.innerHTML = "";
    events.forEach((event, index) => {
      const eventItem = document.createElement("li");
      eventItem.textContent = event;
      eventItem.addEventListener("click", () => callback(event, index));
      eventsMenu.appendChild(eventItem);
    });
  }

  // Display Photos Menu
  async function displayPhotosMenu(year, event) {
    const photos = await fetchData(`/images/${year}/${event}`);
    photosMenu.innerHTML = "";
    photos.forEach((photo) => {
      const photoItem = document.createElement("li");
      photoItem.textContent = photo;
      photoItem.addEventListener("click", () => displayPhoto(year, event, photo));
      photosMenu.appendChild(photoItem);
    });
  }

  // Display a photo
  /*async function displayPhoto(year,  event, photo) {
    const img = document.createElement("img");
    img.src = `/image/${year}/${event}/${photo}`;
    displayContainer.innerHTML = "";
    displayContainer.appendChild(img);
  } */

  // Display a photo
async function displayPhoto(year, event, photo) {
    try {
      const url = `/image/${year}/${event}/${photo}`;
      // Fetch the image as a blob
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to fetch image: ${response.statusText}`);
      }
      const blob = await response.blob();
      // Create an object URL for the blob
      const objectURL = URL.createObjectURL(blob);
      // Create the image element
      const img = document.createElement("img");
      img.src = objectURL; // Assign the object URL
      // Clear the container and display the image
      displayContainer.innerHTML = ""; // Clear the container
      displayContainer.appendChild(img);
      // Optionally release the object URL to free up memory after the image is displayed
      img.onload = () => {
        URL.revokeObjectURL(objectURL); // Clean up memory
      };
    } catch (error) {
      console.error("Error displaying photo:", error);
      // Optionally display an error message or placeholder image
      displayContainer.innerHTML = "<p>Failed to load the photo.</p>";
    }
  }









    // Reset Menus
    function resetMenus() {
        yearsMenu.innerHTML = "";
        eventsMenu.innerHTML = "";
        photosMenu.innerHTML = "";
        subMenuContainer.innerHTML = ""; 
      }

    // Inactivity Timeout Logic
    function resetInactivityTimeout() {
        document.body.style.cursor = "default";
        clearTimeout(inactivityTimeout); // Clear existing timeout
        if (mode == "manual" ){
            if (yearsMenu.innerHTML == "" ){
                menusContainer.style.display = "flex"; // Show menus
                displayYearsMenu((year) => {
                    displayEventsMenu(year, (event) => displayPhotosMenu(year, event));
                  });
            }
        }
        mainMenu.style.display = "block"; // Show main menu
        menusContainer.style.display = "flex";
        subMenuContainer.style.display = "block";


    
        // Set timeout to hide menus after 10 seconds
        inactivityTimeout = setTimeout(() => {
          // Clear menus on user activity
          resetMenus();
          menusContainer.style.display = "none";
          mainMenu.style.display = "none";
          subMenuContainer.style.display = "none";

          displayContainer.style.display = "flex";
          displayContainer.style.justifyContent = "center";
          displayContainer.style.alignItems = "center";
          displayContainer.style.height = "100vh"; // 50% of viewport height
          displayContainer.style.width = "100vw";  // 50% of viewport widt
          displayContainer.style.overflow = "hidden"; // Prevent scrollbars

          document.body.style.cursor = "none"; // Hide the mouse

        }, 10000);
      }
    
      
    // Event listener for mouse movement
    document.addEventListener("mousemove", resetInactivityTimeout);






   // Submenu for Random and Strategic modes
   function displaySubMenu(mode, options, callback) {
    subMenuContainer.innerHTML = ""; // Clear any existing submenu
    const title = document.createElement("h3");
    title.textContent = `Select an option for ${mode} mode:`;
    subMenuContainer.appendChild(title);

    // Create buttons for the options
    options.forEach((option) => {
        const button = document.createElement("button");
        button.textContent = option;
        button.style.display = "block"; // Stack options vertically
        subMenuContainer.appendChild(button);

        // Event listener for the button
        button.addEventListener("click", () => callback(option));
    });
}



    
    // Random photo display logic
    async function displayRandomPhoto(option, selectedYear = null) {
        const years = await fetchData("/years");

        if (option === "completely_random") {
            isDisplayingPhotos_completely_random = true
            let lastPhotos = getCookie("random_photos_last") ? JSON.parse(getCookie("random_photos_last")) : []; // Read the cookie or initialize an empty array
    
            while (isDisplayingPhotos_completely_random) {
                let photoAlreadyDisplayed = true;
                let yearIndex, eventIndex, photoIndex;
    
                // Keep selecting a new photo until it's not in the lastPhotos array
                while (photoAlreadyDisplayed) {
                    // Choose random year, event, and photo indices
                    yearIndex = Math.floor(Math.random() * years.length);
                    let year = years[yearIndex];
    
                    const events = await fetchData(`/events/${year}`);
                    if (events.length == 0){
                        photoAlreadyDisplayed = 1;
                        continue;
                    }
                    eventIndex = Math.floor(Math.random() * events.length);
                    let event = events[eventIndex];
    
                    const photos = await fetchData(`/images/${year}/${event}`);
                    if (photos.length == 0){
                        photoAlreadyDisplayed = 1;
                        continue;
                    }
                    photoIndex = Math.floor(Math.random() * photos.length);
    
                    // Check if the photo is already in the last 50 displayed photos
                    const newPhoto = [yearIndex, eventIndex, photoIndex];
                    photoAlreadyDisplayed = lastPhotos.some(photo => 
                        photo[0] === newPhoto[0] && 
                        photo[1] === newPhoto[1] && 
                        photo[2] === newPhoto[2]
                    );
                }
    
                // Display the photo
                const year = years[yearIndex];
                const events = await fetchData(`/events/${year}`);
                const event = events[eventIndex];
                const photos = await fetchData(`/images/${year}/${event}`);
                const photo = photos[photoIndex];
    
                displayPhoto(year, event, photo);
    
                // Update the lastPhotos FIFO buffer
                lastPhotos.push([yearIndex, eventIndex, photoIndex]);
                if (lastPhotos.length > 50) {
                    lastPhotos.shift(); // Remove the oldest photo to maintain a max size of 50
                }
    
                // Save the updated lastPhotos array in a cookie
                setCookie("random_photos_last", lastPhotos);
    
                // Wait 10 seconds before displaying the next photo
                await new Promise(resolve => setTimeout(resolve, 10000));
            }
    
        }
        
        
        else if (option === "selected_year") {
            isDisplayingPhotos_random_selected_year = true;

            const yearIndex = years.indexOf(selectedYear);

    
            // Retrieve or initialize the last event index from the cookie
            const lastEventState = getCookie("random_selected_year_last");
            let lastEventIndex = 0;
    
            if (lastEventState) {
                const [savedYearIndex, savedEventIndex] = JSON.parse(lastEventState);
                if (savedYearIndex === yearIndex) {
                    lastEventIndex = savedEventIndex;
                }
            }
    
            const events = await fetchData(`/events/${selectedYear}`);
            if (events.length == 0){
                isDisplayingPhotos_random_selected_year = false;
                console.log("Empty events")
            }

            // Main loop for sequential event handling
            while (isDisplayingPhotos_random_selected_year) {
                // Get the current event
                const event = events[lastEventIndex];
    
                // Fetch photos for the current event
                const photos = await fetchData(`/images/${selectedYear}/${event}`);

                if (photos.length != 0) {

    
                    // Randomly select up to 10 photos or display all available photos
                    const photosToShow = photos.length > 10 ? getRandomSubset(photos, 10) : photos;
        
                    // Display each selected photo with a 10-second interval
                    for (let i = 0; i < photosToShow.length && isDisplayingPhotos_random_selected_year; i++) {
                        const photo = photosToShow[i];
                        displayPhoto(selectedYear, event, photo);
                        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait for 10 seconds
                    }
                }
    
                // Save the current state to the cookie
                setCookie("random_selected_year_last", [yearIndex, lastEventIndex]);
    
                // Move to the next event (loop back to the first event if at the end)
                lastEventIndex = (lastEventIndex + 1) % events.length;
            }
        }
    

        else if (option === "random_year") {
            isDisplayingPhotos_random_year = true;

            // Retrieve or initialize the last 7 year indexes from the cookie
            let lastYearIndexes = getCookie("random_last_years") || "[]";
            lastYearIndexes = JSON.parse(lastYearIndexes);
            
        
            // Main loop for displaying photos
            while (isDisplayingPhotos_random_year) {
                // Randomly select a year that is not in the last 7 indexes
                let yearIndex;
                do {
                    yearIndex = Math.floor(Math.random() * years.length);
                } while (lastYearIndexes.includes(yearIndex));
        
                // Update the last 7 year indexes (FIFO buffer)
                lastYearIndexes.push(yearIndex);
                if (lastYearIndexes.length > 7) {
                    lastYearIndexes.shift(); // Remove the oldest entry if buffer exceeds 7
                }
        
                // Save the updated last years to the cookie
                setCookie("random_last_years", lastYearIndexes);
        
                const selectedYear = years[yearIndex];
        
                let eventIndex = 0;
        
                const events = await fetchData(`/events/${selectedYear}`);
                if (events.length == 0){
                    console.log("Empty events")
                    continue;
                }
        
                // Sequentially go through events of the selected year
                while (isDisplayingPhotos_random_year) {
                    const event = events[eventIndex];
        
                    // Fetch photos for the current event
                    const photos = await fetchData(`/images/${selectedYear}/${event}`);

                    if (photos.length != 0) {
        
                        // Randomly select up to 10 photos or display all available photos
                        const photosToShow = photos.length > 10 ? getRandomSubset(photos, 10) : photos;
            
                        // Display each selected photo with a 10-second interval
                        for (let i = 0; i < photosToShow.length && isDisplayingPhotos_random_year; i++) {
                            const photo = photosToShow[i];
                            displayPhoto(selectedYear, event, photo);
                            await new Promise(resolve => setTimeout(resolve, 10000)); // Wait for 10 seconds
                        }
                    }
        
                    // Move to the next event (loop back to the first event if at the end)
                    eventIndex = eventIndex + 1;
        
                    // Break out of the event loop if we are changing the year
                    if (eventIndex === events.length) break;
                }
            }
        }
        


    }




// Sequential display logic
async function sequentialDisplay(option, selectedYear = null, selectedEvent = null) {
    const years = await fetchData("/years");
    let yearIndex = 0;
    let eventIndex = 0;
    let photoIndex = 0;

    // Update control variable to allow the loop to run
    isDisplayingPhotos_sequential = true;

    if (option === "all") {
        const lastState = getCookie("sequential_all_last");
        if (lastState) {
            const [savedYearIndex, savedEventIndex, savedPhotoIndex] = JSON.parse(lastState);
            yearIndex = savedYearIndex || 0;
            eventIndex = savedEventIndex || 0;
            photoIndex = savedPhotoIndex || 0;
        } else {
            yearIndex = 0;
            eventIndex = 0;
            photoIndex = 0;
            var found_non_empy_year = false;
            while (!found_non_empy_year){
                const events = await fetchData(`/events/${years[yearIndex]}`);
                if (events.length != 0){
                    found_non_empy_year = true;
                }
                else{
                    yearIndex++;
                }

            }

        }
    } else if (option === "selected") {
        const lastState = getCookie("sequential_selected_year_last");
        if (lastState) {
            const [savedYearIndex, savedEventIndex, savedPhotoIndex] = JSON.parse(lastState);
            const selectedYearIndex = years.indexOf(selectedYear);

            if (savedYearIndex === selectedYearIndex) {
                yearIndex = savedYearIndex;
                eventIndex = savedEventIndex || 0;
                photoIndex = savedPhotoIndex || 0;
            } else {
                yearIndex = selectedYearIndex;
                eventIndex = 0;
                photoIndex = 0;
            }
        } else {
            yearIndex = years.indexOf(selectedYear);
            eventIndex = 0;
            photoIndex = 0;

            const events = await fetchData(`/events/${years[yearIndex]}`);
            if (events.length != 0){
                isDisplayingPhotos_sequential = false;
                console.log("Empy events")
            }


        }
    } else if (option === "selected_event") {
        yearIndex = years.indexOf(selectedYear);
        const events = await fetchData(`/events/${selectedYear}`);
        eventIndex = events.indexOf(selectedEvent);
        photoIndex = 0;
    }

    while (isDisplayingPhotos_sequential) {
        const year = years[yearIndex];
        const events = await fetchData(`/events/${year}`);
        const event = events[eventIndex];
        const photos = await fetchData(`/images/${year}/${event}`);

        if (photos.length != 0) {

            for (let i = photoIndex; i < photos.length && isDisplayingPhotos_sequential; i++) {
                const photo = photos[i];
                displayPhoto(year, event, photo);

                if (option === "all") {
                    setCookie("sequential_all_last", [yearIndex, eventIndex, i]);
                } else if (option === "selected") {
                    setCookie("sequential_selected_year_last", [yearIndex, eventIndex, i]);
                }

                await new Promise(resolve => setTimeout(resolve, 10000)); // Wait for 10 seconds
            }
        }

        photoIndex = 0;

        if (option === "all") {
            eventIndex++;
            if (eventIndex >= events.length) {
                eventIndex = 0;
                yearIndex++;
                if (yearIndex >= years.length) {
                    yearIndex = 0; // Restart from the beginning
                }
                var found_non_empy_year = false;
                while (!found_non_empy_year){
                    const events = await fetchData(`/events/${years[yearIndex]}`);
                    if (events.length != 0){
                        found_non_empy_year = true;
                    }
                    else{
                        yearIndex++;
                        if (yearIndex >= years.length) {
                            yearIndex = 0; // Restart from the beginning
                        }
                    }
    
                }
            }
        } else if (option === "selected") {
            eventIndex++;
            if (eventIndex >= events.length) {
                eventIndex = 0;
            }
        } else if (option === "selected_event") {
            photoIndex = 0; // Always restart photos for selected_event
        }
    }
}




      // Handle Mode Selection with buttons
      document.querySelectorAll("#main-menu button").forEach((button) => {
        button.addEventListener("click", (event) => {
            const modeId = event.target.id;

            stopPhotoDisplay();
            resetInactivityTimeout();
            resetMenus(); // Reset menus when mode changes

            if (modeId === "manual-mode") {
                mode = "manual";
                displayYearsMenu((year) => {
                    displayEventsMenu(year, (event) => displayPhotosMenu(year, event));
                });
            } else if (modeId === "random-mode") {
                mode = "random";
                displaySubMenu(
                    "random",
                    ["Completely Random", "Selected Year", "Randomly Selected Year"],
                    (selectedOption) => {
                        if (selectedOption === "Completely Random") {
                            displayRandomPhoto("completely_random");
                        } else if (selectedOption === "Selected Year") {
                            displayYearsMenu((year) =>
                                displayRandomPhoto("selected_year", year)
                            );
                        } else if (selectedOption === "Randomly Selected Year") {
                            displayRandomPhoto("random_year");
                        }
                    }
                );
            } else if (modeId === "strategic-mode") {
                mode = "strategic";
                displaySubMenu(
                    "strategic",
                    ["All", "Select Year", "Select Year and Event"],
                    (selectedOption) => {
                        if (selectedOption === "All") {
                            sequentialDisplay("all");
                        } else if (selectedOption === "Select Year") {
                            displayYearsMenu((year) =>
                                sequentialDisplay("selected", year)
                            );
                        } else if (selectedOption === "Select Year and Event") {
                            displayYearsMenu((year) => {
                                displayEventsMenu(year, (event) =>
                                    sequentialDisplay("selected_event", year, event)
                                );
                            });
                        }
                    }
                );
            }
        });
    });


  // Reset inactivity timeout on page load
  resetInactivityTimeout();


    });