#Place Drush archive files in this directory

You will need to change the tasks.yml file to reflect the path of this file in the `sites.archive` object in `config.yml`. Here is an example:
    
    sites:
    - name: site-main
      urls: "127.0.0.1 localhost example.com"
      drush_uri: "example.com"
      archive: 'site-deployment/archives/testdb.20130423_045640.tar.gz'
      db: 'maindb'  #used for both the username and database name
      db_password: 'mypassword'

To generate a drush archive for your site, use [drush archive-dump](http://drush.ws/help/5#archive-dump). For now, you must have that file on your local computer. Future versions could instruct the target system to pull the archive directly from another server. 