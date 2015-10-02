RoRmaily Release Notes
------------------------

This file contains description of changes in each RoRmaily release. It's good to read before updating from earlier versions of RoRmaily, as there might be major changes that the updater should notice, especially when first two numbers in the version numbering are increased.

General update instructions
---------------------------

When updating, always run the following commands to update gem set and database structure:
 - bundle install
 - rake RAILS_ENV=production db:migrate
 - check this file for changes between your old version and the one you are updating, and do the necessary manual operations if needed

 ## Stable Releases

 ####There are not Stable release at the moment

 ## Development Releases

 0.0.1
 -----
 Initial development release, This release is a fork of MailyHerald, with changes in naming, and some extra documentation along with small improvements