# archive_old_data.py
import datetime
import json
import gzip

def archive_old_records():
    cutoff_date = datetime.datetime.utcnow() - datetime.timedelta(days=90)
    records = query_cosmos_db("SELECT * FROM Billing WHERE BillingDate < @cutoff", cutoff_date)
    
    for record in records:
        compressed_data = gzip.compress(json.dumps(record).encode('utf-8'))
        upload_to_blob_storage(f"archive/{record['billingId']}.json.gz", compressed_data)
   
