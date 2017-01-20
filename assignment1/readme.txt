-----------------------------------------------------------------------------------------------------------------------------------------------
								README
-----------------------------------------------------------------------------------------------------------------------------------------------

You are in folder assignment1.
The purpose of this assignment is to configure MRTG and develop a tool which works similar to MRTG. The results are presented through a web dashboard.

This document describes the information about the various files in this folder, modules/software needed and steps to run this assignment.

This folder consists of 7 files in total:
-----------------------------------------


1.backend.pl
2.search.php
3.index.php
4.details.php
5.mrtgconf.pl
6.readme.txt
7.backend.sh
8.backend.pl

Software Requirements:
----------------------

1. Operating System: Ubuntu 14.04 LTS.

2. You need to install Apache server, MySQL and PHP.

3. Modules which are needed to be installed from CPAN are:
	 Data::Dumper
	 DBD::Mysql
	 DBI
   FindBin
   File::Basename
   File::Spec::Functions
	 RRD::Editor
   Net::SNMP
   Net::SNMP::Interfaces
 
Steps to run this assignment:
-----------------------------
1. Go to the terminal in move to the directory where this folder is present, say, /var/www/html/et2536-veti15/assignment1/ 
   (It is assumed that the working directory configured in the apache server is /var/www/html/, change the path accordingly) 

2. To configure MRTG, Run the perl script "mrtgconf.pl" in the terminal with the command "perl mrtgconf.pl".

3. To view the MRTG statistics, use the URL:
   http://localhost/mrtg/

4. To run the developed tool, run the shell script "backend.sh" in the terminal with the command "sh backend.sh".

5. Now, open a web browser and type the following URL: (It is assummed that the folder is in /var/www/html/.
	 http://localhost/et2536-veti15/assignment1/index.php

4. Choose the desired device to view the graphs and statistics.

NOTE:
-----
1. Make sure to create "DEVICES" table in the MySQL database prior to running the backend script in the terminal. 
	 It can be created by following the steps in the major readme.txt file, for all the 4 assignments.

2. Add the following lines to the file "apache2.conf" before configuring the MRTG.
   The path for file is "/etc/apache2/apache2.conf";

Alias /mrtg "/var/www/mrtg/"
 
<Directory "/var/www/mrtg/">
        Options None
        AllowOverride None
        Require all granted
</Directory>

ServerName localhost:80

3. Restart Apache after adding the above lines to apache2.conf
   sudo service apache2 restart

