--Q1 Lahman Baseball
SELECT MIN(yearid), MAx(yearid)
FROM teams;


--Q4

SELECT *
FROM fielding; -- full fielding table for reference

--

SELECT pos, SUM(po) as putouts_position
FROM fielding
GROUP BY pos; -- putouts per position

--

SELECT CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = '2B' THEN 'Infield'
		WHEN pos = '1B' THEN 'Infield'
		WHEN pos = '3B' THEN 'Infield'
		WHEN pos = 'SS' THEN 'Infield'
		WHEN pos = 'P' THEN 'Battery'
		WHEN pos = 'C' THEN 'Battery' END AS position_group,
		SUM (po) as putouts_per_pos
FROM fielding
WHERE yearid = '2016'
GROUP BY position_group; -- putouts per position group 2016

--Q6

SELECT Concat(namefirst,' ',namelast), batting.yearid, ROUND(MAX(sb::decimal/(cs::decimal+sb::decimal))*100,2) as sb_success_percentage
FROM batting
INNER JOIN people on batting.playerid = people.playerid
WHERE yearid = '2016'
AND (sb+cs) >= 20
GROUP BY namefirst, namelast, batting.yearid
ORDER BY sb_success_percentage DESC; --Chris Owings with a %91.3 success rate

--Q7 
--Part 1
SELECT name, yearid, w, WSWin
FROM teams
WHERE yearid >= 1970
AND wswin = 'N'
ORDER BY w DESC; -- Seattle Mariners won 116 games in 2001 without winning WS

--Part 2
SELECT name, yearid, w, WSWin
FROM teams
WHERE yearid >= 1970
AND wswin = 'Y'
ORDER BY w; -- Dodgers won WS in 1981 with 63 wins, there was a strike that year

--Part 3
SELECT name, yearid, w, WSWin
FROM teams
WHERE yearid >= 1970 
AND yearid != 1981
AND wswin = 'Y'
ORDER BY w; -- Cardinals won WS in 2006 with 83 wins (query excludes strike year)

--Part 4
WITH most_wins_per_year AS (SELECT yearid, MAX(w) as max_wins
							FROM teams
							WHERE yearid >= 1970 
							GROUP BY yearid
							ORDER BY yearid)
SELECT COUNT(teams.yearid) as num_teams
FROM teams
INNER JOIN most_wins_per_year
ON teams.yearid = most_wins_per_year.yearid AND teams.w = most_wins_per_year.max_wins
WHERE wswin = 'Y'; -- 12 teams have won the world series and also had the most wins, %25.53

--#9

WITH managers_aw as(SELECT CONCAT(p.namefirst, ' ',p.namelast) as man_name,
						   t.name,
						   am.awardid, am.lgid, am.yearid, m.teamid
					FROM awardsmanagers AS am
					INNER JOIN people AS p
						ON  am.playerid = p.playerid
					INNER JOIN managers AS m
						ON am.playerid = m.playerid AND am.yearid = m.yearid
					LEFT JOIN teams AS t
						ON m.teamid = t.teamid AND m.yearid = t.yearid
					WHERE am.awardid LIKE '%TSN%'
					AND (am.lgid = 'NL' OR am.lgid = 'AL')
					GROUP BY p.namefirst, p.namelast, am.awardid, am.lgid, m.teamid, t.name, am.yearid
					ORDER BY am.yearid)
SELECT DISTINCT(mg1.man_name), mg1.awardid, mg1.lgid, mg1.name, mg2.lgid, mg2.name
FROM managers_aw as mg1
INNER JOIN managers_aw as mg2 USING (man_name)
WHERE (mg1.lgid = 'AL' and mg2.lgid = 'NL');

--Q11

WITH team_s as (SELECT teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2000
					GROUP BY teamid
					ORDER BY  teamid)
SELECT name, SUM(w) as total_wins, team_salary
FROM teams FULL JOIN team_s
ON teams.teamid = team_s.teamid
WHERE teams.yearid >= 2000
GROUP BY teams.name, team_s.team_salary; -- team names,salaries and total wins

--

WITH team_s as (SELECT yearid, teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2000
					GROUP BY yearid, teamid
					ORDER BY yearid, teamid)
SELECT DISTINCT(teams.yearid), SUM(team_salary) as league_salary
FROM teams FULL JOIN team_s
ON teams.teamid = team_s.teamid and teams.yearid = team_s.yearid
WHERE teams.yearid >= 2000
GROUP BY teams.yearid
ORDER BY teams.yearid; -- league salary by year

--

WITH salary1 as (SELECT yearid, teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2000
					GROUP BY yearid, teamid
					ORDER BY yearid, teamid),
	 salary2 as (SELECT yearid, teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2001
					GROUP BY yearid, teamid
					ORDER BY yearid, teamid)
SELECT s1.teamid, s1.yearid, SUM(s1.team_salary), s2.yearid as year_2, SUM(s2.team_salary)
FROM salary1 as s1
INNER JOIN salary2 as s2 USING (teamid)
WHERE s2.yearid = (s1.yearid+1)
GROUP BY s1.teamid, s1.yearid,  s2.teamid, s2.yearid
ORDER BY s1.yearid, teamid; -- year to year change in salary


--

WITH salary1 as (SELECT yearid, teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2000
					GROUP BY yearid, teamid
					ORDER BY yearid, teamid),
	  salary2 as (SELECT yearid, teamid, SUM(salary::varchar::money) as team_salary
					FROM salaries
					WHERE yearid >= 2001
					GROUP BY yearid, teamid
					ORDER BY yearid, teamid),
		wins1 as (SELECT *
				 FROM teams
				 WHERE yearid >= 2000),
		wins2 as (SELECT *
				 FROM teams
				 WHERE yearid >= 2001)
SELECT  w1.name, s1.teamid, s1.yearid, SUM(s1.team_salary), w1.w as wins1, s2.yearid as year_2, SUM(s2.team_salary), w2.w as wins2
FROM salary1 as s1
	INNER JOIN salary2 as s2 USING (teamid)
	LEFT JOIN wins1 as w1 on w1.teamid = s1.teamid and w1.yearid = s1.yearid
	LEFT JOIN wins2 as w2 on w2.teamid = s1.teamid and w2.yearid = s2.yearid
WHERE s2.yearid = (s1.yearid+1)
--AND w1.w < 60
--AND w2.w >90
GROUP BY s1.teamid, s1.yearid,  s2.teamid, s2.yearid, w1.name, w1.w, w2.w
ORDER BY s1.yearid, teamid; -- teams per year with salary changes