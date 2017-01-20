<?php
include './search.php';

// Create connection
$conn = mysqli_connect($host, $username, $password,$database,$port);

// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$query="select * FROM INTERFACES_SHIVI";
$result=mysqli_query($conn,$query);


?>


<html>
	<body>
		<h3 style='text-align: center;'>ASSIGNMENT-1</h3>
<?php

if(mysqli_num_rows($result)>0)
{
while($row=mysqli_fetch_assoc($result))
{
$file="./$row[IP]\:$row[PORT]\:$row[COMMUNITY].rrd";
$file2="./$row[IP]:$row[PORT]:$row[COMMUNITY].rrd";
$data="$row[IP]_$row[PORT]_$row[COMMUNITY]";
$options=array();
	if(file_exists($file2))
	{
		$if_list=explode(':',$row['interfacelist']);
		$if_name=explode(':',$row['interfacename']);
		$combined=array_combine($if_list,$if_name);

		foreach($combined as $a=>$b)
		{
			echo '<div style = "margin: 10px 10px 10px 10px; float: left;">' . $a . ' -- ' . $row['sysname'] . '</br>';
			$options = array(
								"--slope-mode",
								"--start", '-1d',
								"--lower-limit", "0",
								"--vertical-label=bytes per second",
								"--x-grid", "HOUR:1:HOUR:2:HOUR:2:0:%H",
								"--vertical-label=Bytes per Second",
								"DEF:bytesin=".$file.":bytesIn".$a.":AVERAGE",
								"DEF:bytesout=".$file.":bytesOut".$a.":AVERAGE",
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

				$output=$row['IP'] . '_' . $row['PORT'] . '_' . $row['COMMUNITY'] . '_' . $a .'.png';
			  $ret = rrd_graph($output, $options);
			  if (! $ret)
			  {
				echo "<b>Graph error: </b>".rrd_error()."\n";

			}
			
			echo "<a href=details.php?variable=". $a . '_' . $b . '_'. $data."><img src='$output' alt='Generated RRD image' width='500' height='150' align='middle'></a></div>";
			#echo"<a href=.'details.php?'. $a .'=' "><img src='$output' alt='Generated RRD image'></a>" ;
		}
	}
}

}
?>

</body>
</html>
