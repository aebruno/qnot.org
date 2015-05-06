---
date: 2007-06-27 02:56:55+00:00
slug: phpldapadmin-and-kerberos
title: phpLDAPadmin and Kerberos
categories:
  - Hacks
  - PHP
---

I've been experimenting with
[phpLDAPadmin](http://phpldapadmin.sourceforge.net/) for browsing/searching
LDAP directories over the web and found it to be a wonderful tool. I'm
currently working with LDAP in a central authentication system together with
Kerberos and wanted to have a nice web interface for managing user information
within the LDAP directory. phpLDAPadmin provides a very nice interface for
browsing, searching, and updating entries which makes it a bit easier than
working with the ldap* command line tools. Here's my basic setup of
phpLDAPadmin using Kerberos for authentication. This assumes you already have
an LDAP/Kerberos setup working and are using Apache as your web server.<!--more-->

First step is to make sure you have
[SASL](http://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer)
support compiled into the LDAP PHP extension `--with-ldap-sasl`. Check out
phpinfo() and make sure you see `SASL Support   Enabled` under the LDAP
extension. If not re-compile PHP.  <!--more-->
Grab a copy of phpLDAPadmin
[here](http://phpldapadmin.sourceforge.net/download.php) and untar into a
directory of your choice (/usr/local). Copy the config.php.example to
config.php:

{{< highlight bash >}}
$ tar -xvxf phpldapadmin-x.x.x.tar.gz
$ ln -s phpldapadmin-x.x.x phpldapadmin
$ cd phpldapadmin
$ cp config/config.php.example config/config.php
{{< /highlight >}}

Edit config/config.php. A few options to define are as follows:

{{< highlight php >}}
$ldapservers->SetValue($i,'server','name','My LDAP Server');
$ldapservers->SetValue($i,'server','host','ldap.host.com');
$ldapservers->SetValue($i,'server','port','389');
$ldapservers->SetValue($i,'server','auth_type','config');
$ldapservers->SetValue($i,'login','dn','');
$ldapservers->SetValue($i,'login','pass','');
$ldapservers->SetValue($i,'server','tls',false);
$ldapservers->SetValue($i,'server','sasl_auth',true);
$ldapservers->SetValue($i,'server','sasl_mech','GSSAPI');
$ldapservers->SetValue($i,'server','sasl_authz_id_regex','/^uid=([^,]+)(.+)/i');
$ldapservers->SetValue($i,'server','sasl_authz_id_replacement','$1');
$ldapservers->SetValue($i,'login','anon_bind',false); 
{{< /highlight >}}

Basically, we're configuring phpLDAPadmin with `auth_type = config` which means
that the user/pass used to bind to the LDAP server is hard coded in the
config.php file. We leave the user/pass blank because each user will first be
authenticating through Kerberos and using their tickets to bind to the LDAP
server. Internally phpLDAPadmin calls the [ldap_sasl_bind(..)](http://us.php.net/manual/en/function.ldap-sasl-bind.php)
function with an `auth_mech` of
[GSSAPI](http://en.wikipedia.org/wiki/Generic_Security_Services_Application_Program_Interface)
which does the work of binding using Kerberos tickets.

Next, we'll configure apache to point to the location where we installed
phpLDAPadmin. Edit your httpd.conf file or equivalent. If your running redhat
usually create a file in /etc/httpd/conf.d or on Debian
/etc/apache2/site-available/. You will probably want to add this to an SSL
vhost to ensure your username/passwords are transmitted over a secure
connection.

{{< highlight apache >}}
Alias /ldapadmin /usr/local/phpldapadmin/htdocs/
<Location /ldapadmin>
    AuthType Kerberos
    AuthName "LDAP Admin"
    KrbAuthRealms kerb.yourhost.com
    KrbVerifyKDC off
    KrbServiceName HTTP
    Krb5KeyTab /path/to/your/httpd.keytab
    KrbSaveCredentials on
    require valid-user
</Location>
{{< /highlight >}}

In order to authenticate users against Kerberos and obtain the necessary
Kerberos tickets we use the apache module
[mod_auth_kerb](http://modauthkerb.sourceforge.net/). The apache config above
defines our location for phpLDAPadmin and adds in the necessary config for
mod_auth_kerb. More info can be found
[here](http://modauthkerb.sourceforge.net/configure.html). Make sure to add in
the `KrbSaveCredentails on` directive so that mod_auth_kerb will save the
Kerberos tickets for use throughout the request.

Next we need to expose the location of the Kerberos tickets to phpLDAPadmin.
mod_auth_kerb sets an environment variable `KRB5CCNAME` to the location of the
credential cache. To expose this environment variable to the phpLDAPadmin code
edit the file `[phpLDAPadmin_install]/lib/common.php` and add this line to the
very top:

{{< highlight php >}}
putenv("KRB5CCNAME={$_SERVER['KRB5CCNAME']}"); 
{{< /highlight >}}

That should do it. Now when you access http://yourserver.com/ldapadmin you
should be challenged with HTTP basic auth, which authenticates against Kerberos
and uses the Kerberos credentials to bind to your LDAP server. There might be
an easier way to go about doing this but I wasn't able to turn much up on
google so I thought I'd share one way I was able to get things working.
