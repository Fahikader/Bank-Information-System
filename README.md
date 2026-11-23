# Bank Information System (SQL Server)

A relational database project built in **Microsoft SQL Server (T-SQL)** designed to manage banking operations, including client profiles, account management, automated IBAN generation, transaction processing, and audit logging.

---

## 📊 Database Schema (ERD)

![Database Diagram](erd_diagram.png)

*(Note: Make sure your uploaded diagram image is named `erd_diagram.png` in the main folder, or update the filename above to match).*

---

## 🗂️ Database Structure

### Tables
* **`client`** — Stores customer personal details and contact information.
* **`cities`** — Lookup table containing city references linked to client records.
* **`account`** — Core banking account records linked to clients.
* **`account_detail`** — Stores detailed account attributes, balances, and metadata.
* **`account_cache`** — Intermediate/cached account state used for fast lookups and trigger tracking.
* **`log`** — Audit trail table capturing inserts, updates, and system events across tables.

### Views
* **`Client_accounts`** — Combines client details with their associated bank accounts.
* **`Customer_data`** — Consolidated view of customer profiles and location data.

### Programmability (Procedures, Functions & Triggers)
* **Functions:**
  * `To_Generate_IBAN` — Automatically generates formatted IBAN numbers for accounts.
* **Stored Procedures:**
  * `Amount_Transaction` — Handles secure balance transfers and transaction execution.
  * `Customer_Update` — Updates customer information cleanly.
  * `Ins_Update` — Manages insert and update operations on account records.
* **Triggers:**
  * Automated DML triggers (`Trigger_LOG_Client`, `Trigger_LOG_Cities`, `Trigger_LOG_AccountDetail`, `Trigger_Account_Cache`, etc.) that record changes into the `log` table and maintain cache consistency.

---

## 🚀 How to Run This Database Locally

1. **Download the files:** Clone this repository or download `Bank_Information_System.mdf` and `Bank_Information_System_log.ldf` from the `Bank_Information_System` folder.
2. **Move to SQL Server DATA directory:** Copy both files into your local SQL Server `DATA` folder (for example: `C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\`).
3. **Attach in SSMS:**
   * Open **SQL Server Management Studio (SSMS)** and connect to your local instance.
   * Right-click **Databases** in Object Explorer and select **Attach...**
   * Click **Add...**, select `Bank_Information_System.mdf`, and click **OK**.
4. **Explore:** Expand `Bank_Information_System` to view tables, diagrams, views, and stored procedures.

---

## 🛠️ Technologies Used
* **Database Engine:** Microsoft SQL Server (Express Edition)
* **Query Language:** T-SQL
* **Management Tool:** SQL Server Management Studio (SSMS)
