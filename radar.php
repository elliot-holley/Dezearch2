<?php
// redirect browser to the latest Met Office radar map
$date = (date("i") < 30) ? date("YmdH00") : date("YmdH00");
$imageURI = 'http://www.metoffice.gov.uk/weather/images/uk_britradar_' . $date . '.gif';
header("Location: $imageURI");
?> 
