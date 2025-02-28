CREATE DATABASE WWorganization;

-- Use the database
USE WWorganization;


CREATE TABLE Warehouse (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(255) NOT NULL UNIQUE, 
    location VARCHAR(255) NOT NULL
); 

CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY IDENTITY(1,1),
    item_name VARCHAR(255) NOT NULL UNIQUE,
    item_type VARCHAR(255) NOT NULL CHECK (item_type IN ('Raw Material', 'Component', 'Finished Product')),
    quantity_available INT NOT NULL CHECK (quantity_available >= 0),
    warehouse_id INT,
    last_updated DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id) ON DELETE SET NULL
);





CREATE TABLE Inventory_Transactions (
    transaction_id INT PRIMARY KEY 
    inventory_id INT,
    transaction_type VARCHAR(255) NOT NULL CHECK(transaction_type IN ('Add', 'Remove', 'Adjust')),  
    quantity INT NOT NULL CHECK (quantity > 0),  -- Positive quantity only
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,  
    FOREIGN KEY (inventory_id) REFERENCES Inventory(inventory_id) ON DELETE CASCADE 
);

CREATE TABLE Production_Plan (
    plan_id INT PRIMARY KEY,
    product_id INT,
    scheduled_start_date DATE NOT NULL,
    scheduled_end_date DATE NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Inventory(inventory_id)
);




CREATE TRIGGER trg_CheckEndDate
ON Production_Plan
AFTER INSERT, UPDATE
AS
BEGIN
    -- Check if the end date is earlier than the start date
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE scheduled_end_date < scheduled_start_date
    )
    BEGIN
        RAISERROR('Scheduled end date cannot be earlier than start date.', 16, 1);
        ROLLBACK TRANSACTION;  -- Prevent the insert/update from happening
    END
END;

CREATE TABLE Production_Resources (
    resource_id INT PRIMARY KEY,
    resource_name VARCHAR(255) NOT NULL UNIQUE, 
	availability_status VARCHAR(255) NOT NULL CHECK(availability_status IN ('Available', 'Unavailable'))
);



CREATE TABLE Production_Progress (
    progress_id INT PRIMARY KEY,
    plan_id INT,
    status VARCHAR(255) NOT NULL CHECK( status IN ('In Progress', 'Completed', 'Delayed')),
    actual_start_date DATE,
    actual_end_date DATE,
    FOREIGN KEY (plan_id) REFERENCES Production_Plan(plan_id)
);





-- Order Processing Tables


-- Order Processing Tables

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    contact_info VARCHAR(255) NOT NULL UNIQUE
);



DELETE Customers
CREATE TABLE Customer_Orders (
    order_id INT PRIMARY KEY
    customer_id INT,
    order_date DATE NOT NULL,
    order_status VARCHAR(50) NOT NULL CHECK (order_status IN ('Pending', 'Shipped', 'Delivered')),
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE
);


CREATE TABLE Order_Details (
    order_detail_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL CHECK (quantity > 0), 
    price_per_unit DECIMAL(10, 2) NOT NULL CHECK (price_per_unit > 0), 
    FOREIGN KEY (order_id) REFERENCES Customer_Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Inventory(inventory_id) ON DELETE CASCADE
);




-- Supply Chain Management Tables


CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL UNIQUE,  
    contact_info VARCHAR(255) NOT NULL UNIQUE 
);


CREATE TABLE Purchase_Orders (
    po_id INT PRIMARY KEY,
    supplier_id INT,
    order_date DATE NOT NULL,
    expected_delivery_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Pending', 'Received', 'Cancelled')),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

CREATE TRIGGER trg_CheckDeliveryDate
ON Purchase_Orders
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE expected_delivery_date < order_date
    )
    BEGIN
        RAISERROR('Expected delivery date cannot be earlier than the order date.', 16, 1);
        ROLLBACK TRANSACTION; 
    END
END;




CREATE TABLE Inbound_Shipments (
    shipment_id INT PRIMARY KEY,
    po_id INT,
    received_date DATE NOT NULL,
    quantity_received INT NOT NULL CHECK (quantity_received > 0), 
    FOREIGN KEY (po_id) REFERENCES Purchase_Orders(po_id) ON DELETE CASCADE
);

DELETE Warehouse