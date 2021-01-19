#!/bin/sh

if [ -f artisan ]
then
	php artisan config:clear
	php artisan cache:clear
	php artisan migrate --force
	php artisan queue:restart
	php artisan view:cache
fi

exit 0;
