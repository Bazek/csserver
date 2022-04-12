<!DOCTYPE html>
<html>
	<head>
		<link rel="stylesheet" href="css/bootstrap.min.css" type="text/css">
		<link rel="stylesheet" href="css/chart.css" type="text/css">
		<link rel="stylesheet" href="css/flag-icon.min.css" type="text/css">
		<script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js" integrity="sha384-wHAiFfRlMFy6i5SRaxvfOCifBUQy1xHdJ/yoi7FRNXMRBu5WHdZYu1hA6ZOblgut" crossorigin="anonymous"></script>
		<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>		<title>Player Status in DB - {% block title %}{% endblock %}</title>
		<script src="js/jquery.easypiechart.min.js"></script>
		{% block javascript %}{% endblock %}
		{% block stylesheet %}{% endblock %}
	</head>
	<body topmargin="0" leftmargin="-2">
	<div class="container" style="max-width:none">
		<h1>Velikonoční Stylování 2022</h1>
		{% block content %}{% endblock %}
	</div>
	</body>
</html>