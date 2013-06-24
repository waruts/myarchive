

jQuery(document).ready(function() {

  /* Hide/Show advanced option */
  jQuery('.advanced_option').hide(); // set default to hide

  jQuery("#show_advanced").click(function(event) { // if link is clicked
    event.preventDefault(); // don't go to another page
    if (jQuery('.advanced_option').is(':hidden')) { // if it is hidden, slide down
      jQuery('.advanced_option').slideDown();
      jQuery("#show_advanced").html("Hide advanced options");
    } else { // if not, slide up
      jQuery('.advanced_option').slideUp();
      jQuery("#show_advanced").html("Show advanced options");
    }
  });

  /* Generate suggested tag */
  jQuery("#year").blur(function() { // if user leaves year field
    var author_string = jQuery("#author").val();
    if (author_string == '') return;

    var author_array = author_string.split(" and "); // split by 'and'
    
    for (var i = 0; i < author_array.length; i++) { 
      author_array[i] = jQuery.trim(author_array[i]); // trim whitespace
      comma_index = author_array[i].indexOf(",");
      if (comma_index != -1) { // has a comma -- format LastName, FirstName
        author_array[i] = author_array[i].substring(0, comma_index);
        space_index = author_array[i].indexOf(" ");
        if (space_index != -1) {
          author_array[i] = author_array[i].substring(0, space_index);
        }
      }
      else { // no comma -- format FirstName LastName
        last_space_index = author_array[i].lastIndexOf(" "); 
        if (last_space_index != -1) { // take last string (probably last name)
          author_array[i] = author_array[i].substring(last_space_index + 1); 
        }
      }
    }

    tag_suggestion = author_array[0]; // first author
    if (author_array.length > 1) {
      tag_suggestion += author_array[1].substring(0, 2);
    }
    if (author_array.length > 2) {
      tag_suggestion += author_array[2].substring(0, 2);
    }    

    var year_string = jQuery("#year").val();
    if (year_string == '') return;
    tag_suggestion += year_string.slice(-2);

    jQuery("#name").val(tag_suggestion);
  });




});
