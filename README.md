# csv_seed
Import csv data to rails projects.

Why a new seed gem?
- Csv is easier to read and update than fixtures or seeds.
- Associations in csv tables can be applied to real databases.
...

How to use?
1. gem install csv_seed
2. prepare data. see test/dummy/db/seeds/*/*.csv
3. run command 'csv_seed import --from source'. for example, 'csv_seed import --from case001', the csv files of thdb/seeds/case001 should be imported.

##### If using Rails 5, 'optional: true' should be add to belongs_to associations.

to be continued...
