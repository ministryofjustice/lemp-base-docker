#!/bin/sh

if [ -f artisan ]
then
	php artisan config:clear
	php artisan cache:clear
	php artisan migrate --force
	php artisan queue:restart
fi
