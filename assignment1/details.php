<?php
include './search.php';

// Create connection
$conn = mysqli_connect($host, $username, $password,$database,$port);

// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$compname = $_GET['variable'];
$details=explode('_',$compname );
$ifno=$details[0];
$ifnam = $details[1];
$ip=$details[2];
$port=$details[3];
$community=$details[4];

if(!empty($compname))
{
	$query="select * FROM INTERFACES_SHIVI where IP='$ip' and PORT='$port' and COMMUNITY='$community'  ";
$result=mysqli_query($conn,$query);

while($row=mysqli_fetch_assoc($result))
{
?>

<html>
	<body>
		<h3>
			<?php echo '#' . $ifnam . ' -- ' . $row[sysname]; ?>
		</h3>
		<table style = "text-align: left;" cellpadding="2" cellspacing="2">
			<tr>
				<th>
					<?php echo 'system name';?>
				</th>
				<td>
				<?php echo $row['sysname'];?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'system contact';?>
				</th>
				<td>
								<?php echo $row['syscontact'];?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'system location';?>
				</th>
				<td>
								<?php echo $row['syslocation'];?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'system uptime';?>
				</th>
				<td>
								<?php echo $row['sysuptime'];?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'interfacename';?>
				</th>
				<td>
								<?php echo $ifnam;?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'lastupdate';?>
				</th>
				<td>
								<?php echo $row['lastupdate'];?>
				</td>
			</tr>
			<tr>
				<th>
					<?php echo 'IP';?>
				</th>
				<td>
								<?php echo $ip;?>
				</td>
			</tr>
		
		
		</table></br>


<?php

	$file="$ip\:$port\:$community.rrd";

$graphs=array(
			'd'=>'HOUR:1:HOUR:2:HOUR:2:0:%H',
			'w'=>'DAY:1:DAY:1:DAY:1:86400:%a',
			'm'=>'WEEK:1:WEEK:1:WEEK:1:604800:%V',
			'y'=>'MONTH:1:MONTH:1:MONTH:1:2419200:%Y',
			);
$title=array(
			'd'=>'daily graph',
			'w'=>'weekly graph',
			'm'=>'monthly graph',
			'y'=>'yearly graph',
			);

foreach($graphs as $key => $values)
{
	$options = array(
						"--slope-mode",
						"--start", '-1'.$key,
						"--lower-limit", "0",
						"--title=".$title[$key],
						"--vertical-label=bytes per second",
						"--x-grid", $values,
						"--vertical-label=Bytes per Second",
						"DEF:bytesin=".$file.":bytesIn".$ifno.":AVERAGE",
						"DEF:bytesout=".$file.":bytesOut".$ifno.":AVERAGE",
						"VDEF:max_in=bytesin,MAXIMUM",
						"VDEF:max_out=bytesout,MAXIMUM",
						"VDEF:avg_in=bytesin,AVERAGE",
						"VDEF:avg_out=bytesout,AVERAGE",
						"VDEF:cur_in=bytesin,LAST",
						"VDEF:cur_out=bytesout,LAST",
						"CDEF:tbytesin=bytesin,1,*",
						"CDEF:tbytesout=bytesout,1,*",
						"COMMENT:\\n",
						"COMMENT:\\t",
						"COMMENT:\\t",
						"COMMENT: MAXIMUM",
						"COMMENT:     AVERAGE",
						"COMMENT:       CURRENT\\n",
						#"COMMENT: \\s",

						"AREA:bytesin#00FF00:bytesin\\t",
						"GPRINT:max_in: %6.2lf %SBps",
						"GPRINT:avg_in: %6.2lf %SBps",
						"GPRINT:cur_in: %6.2lf %SBps\\n",
						"COMMENT:\\n",

						"LINE1:bytesout#0000FF:bytesout\\t",
						"GPRINT:max_out: %6.2lf %SBps",
						"GPRINT:avg_out: %6.2lf %SBps",
						"GPRINT:cur_out: %6.2lf %SBps\\n"
		
	  );

		$output=$row['IP'] . '_' . $row['PORT'] . '_' . $row['COMMUNITY'] . '_' . $a . $key .'.png';
	  $ret = rrd_graph($output, $options);
	  if (! $ret) {
		echo "<b>Graph error: </b>".rrd_error()."\n";

	}
	echo"<img src='$output' alt='Generated RRD image'></br></br>" ;

}
echo "</table>";
exit;



  
}
}

?>
</body>
</html>

