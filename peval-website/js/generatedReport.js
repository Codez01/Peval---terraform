function fetchReportJSON() {
  const queryString = window.location.search; // get the url from the browser

  const urlParams = new URLSearchParams(queryString);
  if (urlParams.get("file") != null) {
    try {
      fetch(urlParams.get("file"))
        .then((response) => response.json())
        .then((report) => {
          console.log(report);

          let PerfData = report["data"];
          let OverallPerf = report["overall_performance"];
          let OverallPerf_be = OverallPerf["be"];
          let OverallPerf_fe = OverallPerf["fe"];
          let ReportDate = report["date_time"];
          let iconColor = "#606BFD";

          $(".report-gen-wrapper #reportsContainer h1").text(
            "Generated Report - " + ReportDate
          );

          $(".report-wrapper #reportsContainer").append(`

      <h1 style="text-align: center; color: black;">Overall Performance Score</h1>
      <div class="Performance-container align-content-center" style="margin-top:2%;">
      <div style="text-align: center;">

          <i class="col-1 bi bi-layers-fill align-content-center"
              style="font-size: 60px; color:#5864FF;"> </i>
          <span class="align-middle" style="width: 23%; ">
              <h5 style=" color: black;  margin-bottom: 6%; margin-right: 0.1%">
                  Average Front-end response
                  time: ${OverallPerf_fe} seconds</h5>
          </span>


          <i class="col-1 bi bi-server align-content-center" style="font-size: 60px; color:#5864FF;">
          </i>

          <span class="align-content-end" style="width: 23%;">
              <h5 style=" color: black;  margin-bottom: 6%;">Average Back-end
                  response
                  time: ${OverallPerf_be} seconds</h5>
          </span>
      </div>

      <hr style="text-align: center; width:50%; margin: auto; margin-top: 3%;">

      <h1 style="text-align: center; color: black; margin-top: 5%;">Main & sub-sites performance</h1>
      <div class="Performance-container align-content-center">


      </div>
      </div>
  </div>

      `);
          for (subSite in PerfData) {
            $(".report-wrapper #reportsContainer .Performance-container")
              .append(`
      
        <div>
            <i class="col-1 bi bi-laptop-fill align-content-center" style="font-size: 60px; color: ${iconColor};"> </i>
            <span class="align-middle" style="    width: 70%;">
                <h5 style=" color: black;  margin-top: 4%; margin-bottom: 6%; margin-right: 0.1%">
                    ${subSite}
                </h5>
            </span>
            <div>
                <i class="col-1 bi bi-server align-content-center" style="font-size: 60px; color: ${iconColor};">
                </i>

                <span class="align-content-end" style="width: 50%;">
                    <h5 style=" color: black;  margin-bottom: 6%;">
                        Back-end
                        response
                        time:  ${PerfData[subSite]["performance"]["be"]} seconds </h5>
                </span>
            </div>
            <div>
                <i class="col-1 bi bi-layers-fill align-content-center" style="font-size: 60px; color: ${iconColor};">
                </i>

                <span class="align-content-end" style="width: 50%;">
                    <h5 style=" color: black;  margin-bottom: 6%;">
                        Front-end
                        response
                        time: ${PerfData[subSite]["performance"]["fe"]} seconds </h5>
                </span>
            </div>

            <hr>
            `);
          }
        })
        .catch((error) => {
          console.log(error);
          $(".report-wrapper #reportsContainer").append(
            `<h1 style="text-align: center; color:red; ">An Error Occured, Please try again later... <h1>`
          );
        });
    } catch {}
    console.log(res);
  }
}

fetchReportJSON();
