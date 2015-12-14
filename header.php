<?php
function generateHeader()
{
	echo '

	<div id = "header">
		
			<span id = "pageTitle">
				<a href = "index.php"> Eric Kofman </a>
			</span>
			
			<ul>
	
				<li> <a href = "projects.php"> Projects </a> </li>
				<li> <a href = "art.php"> Art </a> </li>
				<li> <a href = "music.php"> Music </a> </li>
				<li> <a href = "origami.php"> Origami </a> </li>
				<li> <a target="_blank" href = "http://www.inkorrigible.blogspot.com"> Webcomic </a> </li> 
			</ul>
			
			<span id = "selfPortrait">
				<img src = "img/selfPortrait.jpg" width = "120px">
			</span>
			<img src = "img/swish.png" >
		</div>
		
	';
}
?>