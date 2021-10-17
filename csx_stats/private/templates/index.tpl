{% extends 'inc_base.tpl' %}
{% block title   %}Top Ranking{% endblock %}
{% block content %}
		<table class="table table-hover">
			<thead>
			<tr>
				<th scope="col" rowspan="2" style="min-width:40px">Rank</th>
				<th scope="col" rowspan="2"></th>
				<th scope="col" rowspan="2"></th>
				<th scope="col" rowspan="2" style="min-width:160px">Name</th>
				<th scope="col" rowspan="2" style="min-width:70px">Score</th>
				<th scope="col" rowspan="2" style="min-width:45px">Kills</th>
				<th scope="col" rowspan="2" style="min-width:60px">Deaths</th>
				<th scope="col" rowspan="2" style="min-width:70px">Rate</th>
				<th scope="col" rowspan="2" style="min-width:80px">TeamKills</th>
				<th scope="col" rowspan="2" style="min-width:60px">Shots</th>
				<th scope="col" rowspan="2" style="min-width:50px">Hits</th>
				<th scope="col" rowspan="2" style="min-width:100px">Accuracy</th>
				<th scope="col" rowspan="2" style="min-width:75px">Damages</th>
				<th scope="col" rowspan="2" style="min-width:85px">Efficiency</th>
				<th scope="col" rowspan="2" style="min-width:80px">ELO</th>
				<!--
				<th scope="col" rowspan="2">HeadShots</th>
				<th scope="col" rowspan="2">HS Accuracy</th>
				<th scope="col" colspan="8">HIT POSITIONS</th>
				-->
			</tr>
			<!--
			<tr>
				<th scope="col">HEAD</th>
				<th scope="col">CHEST</th>
				<th scope="col">STOMACH</th>
				<th scope="col">LEFT ARM</th>
				<th scope="col">RIGHT ARM</th>
				<th scope="col">LEFT LEG</th>
				<th scope="col">RIGHT LEG</th>
				<th scope="col">SHILED (NOT WORKING)</th>
			</tr>
			-->
			</thead>
			<tbody>
			{% for record in ranking %}
			<tr class="table-dark">
				<td scope="row"><strong>{{ record.csx_rank }}</strong></td>
				<td>
					<span class="flag-icon flag-icon-{{record.country}}"></span>
				</td>
				<td>
					<a href="{{record.steam_data.profileurl}}" target="_blank" ><img src="{{record.steam_data.avatar}}"></a>
				</td>
				<td>
					<form method="post" name="user_rank" action="user_detail.php">
						<input type="hidden" name="auth_id" value="{{ record.auth_id }}" />
						{% if record.name|trim matches '#^(\[[A-Z][A-Z]\])?.*(Player)$#' or record.name|trim matches '#^(\(\d\))?Player$#'%}
							<a href="#" onclick="javascript:user_rank[{{ loop.index0 }}].submit()">{{ record.steam_data.personaname }}</a>
						{% else %}
							<a href="#" onclick="javascript:user_rank[{{ loop.index0 }}].submit()">{{ record.name }}</a>
						{% endif %}
					</form>
				</td>
				<td>{{ record.csx_score }}</td>
				<td>{{ record.csx_kills }}</td>
				<td>{{ record.csx_deaths }}</td>
				<td>{{ record.kdrate }}</td>
				<td>{{ record.csx_tks }}</td>
				<td>{{ record.csx_shots }}</td>
				<td>{{ record.csx_hits }}</td>
				<td>{{ record.accuracy }}%</td>
				<td>{{ record.csx_dmg }}</td>
				<td>{{ record.efficiency }}%</td>
				<td><img src="images/{{ record.csx_elo }}" style="width:75px" alt="{{record.csx_elo_name}}"></td>
				<!--
				<td>{{ record.csx_hs }}</td>
				<td>{{ record.accuracyHS }}</td>
				<td>{{ record.h_head }}</td>
				<td>{{ record.h_chest }}</td>
				<td>{{ record.h_stomach }}</td>
				<td>{{ record.h_larm }}</td>
				<td>{{ record.h_rarm }}</td>
				<td>{{ record.h_lleg }}</td>
				<td>{{ record.h_rleg }}</td>
				<td>{{ record.h_shield }}</td>-->
			</tr>
			{% endfor %}
			</tbody>
		</table>
{% endblock %}
