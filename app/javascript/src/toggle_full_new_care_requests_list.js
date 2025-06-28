// Toggle a patient care request list between recent few and full rack.
const toggleFullCareRequestList = () => {
  $(document).on('click', '#toggle-care-request-log', function() {
    $(".old-care-requests").toggleClass("d-none");
    const html = $(".old-care-requests").hasClass("d-none") ? "View all care requests" : "Limit list";
    $("#toggle-care-request-log").html(html);
  });
};

$(document).on('DOMContentLoaded', toggleFullCareRequestList);
