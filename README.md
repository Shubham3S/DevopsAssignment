# Azure Billing Records Cost Optimization

---

## 📋 Problem Summary

We have an Azure serverless system storing billing records in Azure Cosmos DB.  
- Each billing record can be up to 300 KB in size.  
- The database holds over 2 million records.  
- The system is read-heavy, but records older than 3 months are rarely accessed.  
- Cosmos DB storage and throughput costs have grown significantly.  

---

## 🎯 Goals & Constraints

- **Reduce Cosmos DB costs** by archiving old records to cheaper storage.  
- **No data loss** and **no downtime** during migration.  
- **No changes to existing read/write APIs**.  
- Serve archived record reads within seconds.  
- Simple, scalable, and maintainable solution.  

---

## 🧠 ChatGPT Prompt Used

> I have a cost optimization challenge in an Azure serverless architecture.  
> - Billing records stored in Azure Cosmos DB.  
> - Records older than 3 months rarely accessed.  
> - Each record size ~300 KB, total > 2 million records.  
> - No data loss, no downtime, no API changes.  
> - Need cost optimization while maintaining performance.  
> Please propose detailed architecture, pseudocode, and scripts, including an architecture diagram.

---

## 🏗 Proposed Architecture

![Architecture Diagram](./architecture-diagram.png)  
*Diagram: Cosmos DB holds recent (<3 months) active billing data; older data archived to Azure Blob Storage. Azure Functions handle archival and fallback retrieval.*

| Component               | Purpose                                         |
|------------------------|------------------------------------------------|
| Azure Cosmos DB        | Stores active billing records (<= 3 months)    |
| Azure Blob Storage     | Archives old billing records (> 3 months)      |
| Azure Functions        | 1. Timer-triggered archival of old records<br>2. HTTP-triggered fallback reads from Blob Storage |
| Azure Durable Timer    | Triggers archival jobs on schedule              |
| (Optional) Azure CDN/Front Door | Speeds up Blob Storage access for archived data |

---

## ⚙️ Core Strategy

1. **Archive Old Records**  
   Periodically move records older than 3 months from Cosmos DB to Blob Storage as compressed JSON files. Optionally mark or delete archived records from Cosmos DB.

2. **Read with Fallback**  
   When reading a record, first query Cosmos DB. If not found, fallback to Blob Storage to retrieve archived data.

3. **Zero Downtime Migration**  
   Archival runs in the background with retries and state tracking. APIs remain unchanged.

4. **Cost Optimization**  
   - Blob Storage Cold/Archive tiers reduce storage cost for infrequently accessed data.  
   - Compression (GZIP/Parquet) reduces data size.  
   - Read throttling and caching reduce function invocations.

---

## 🧾 Pseudocode Summary

### Archival Function (`functions/archive_old_data.py`)
```python
import datetime
import json
import gzip

def archive_old_records():
    cutoff_date = datetime.datetime.utcnow() - datetime.timedelta(days=90)
    records = query_cosmos_db("SELECT * FROM Billing WHERE BillingDate < @cutoff", cutoff_date)
    
    for record in records:
        compressed = gzip.compress(json.dumps(record).encode('utf-8'))
        upload_to_blob(f"archive/{record['billingId']}.json.gz", compressed)
        # Optionally delete or mark archived in Cosmos DB
