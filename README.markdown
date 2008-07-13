Tangram Importer
================

Tangram-importer is a small Sinatra application that serves as web-API to let
people import contacts from a variety of web accounts without using a password.

A bit like the Plaxo importer, but FOSS, and using only authentification protocols
which don't require giving out your password.

For that, the example.com website could tells its users to click on :

    http://tangram-importer.example.com/contacts/yahoo?format=yml&return_to=http://example.com/return-url

Then, tangram-importer takes the user by the hand, redirecting on the website,
and POSTs the result on the given `return_to` URI, in the given format (yml, xml, csv).

To launch a development app, type:

    ruby tangram-importer.rb

Then try it out at:

    http://localhost:4567/?return_to=http://localhost:4567/implementation-test&format=xml

