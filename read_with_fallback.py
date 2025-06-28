# read_with_fallback.py
import json
import gzip

def get_billing_record(billing_id):
    record = read_from_cosmos_db(billing_id)
    if record:
        return record
    else:
        blob_data = download_from_blob_storage(f"archive/{billing_id}.json.gz")
        if blob_data:
            return json.loads(gzip.decompress(blob_data))
        else:
            raise RecordNotFoundError()
