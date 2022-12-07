function sendWebsiteToLambda() {
  const website = $("#website-url").val();
  console.log(website);

  if (isValidHttpUrl(website) != false) {
    try {
      $.ajax({
        url: `https://kqu36cddcj.execute-api.us-east-1.amazonaws.com/development/triggerwebsite?website=${website}`,
        type: "GET",
        dataType: "json", // added data type
        success: function (res) {
          console.log(res);
        },
      });
    } catch (error) {
      console.log("Error: " + error);
    }
  } else {
    alert("Error: Invalid URL");
  }

  alert("Website is sent for report generation");
}

function isValidHttpUrl(string) {
  let url;
  try {
    url = new URL(string);
  } catch (_) {
    return false;
  }
  return url.protocol === "http:" || url.protocol === "https:";
}
