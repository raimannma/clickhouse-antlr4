BACKUP TABLES db.t1, db.t2 EXCEPT TABLES db.t_private TO S3('https://s3.example.com/bucket', 'AK', 'SK') SETTINGS async = 1
