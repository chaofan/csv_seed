# csv_seed
Import csv data to rails projects.

Why a new seed gem?
- Csv is easier to read and update than fixtures or seeds.
- Associations in csv tables can be applied to real databases.
...

How to use?
- gem 'csv_seed'
- prepare your data. see test/dummy/db/seeds/**/*.csv
- thor csv:seed --use folder (which are subfolders of 'db/seeds/')

#### If using Rails 5, 'optional: true' should be add to belongs_to associations.

to be continued...
