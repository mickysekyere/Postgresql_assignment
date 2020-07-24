--Number of Wave Users
SELECT COUNT(u_id) FROM USERS;


--Numbers of transfers done in CFA
SELECT COUNT(transfer_id) FROM transfers
WHERE send_amount_currency = 'CFA';


--Different Users that have made transfers in CFA
SELECT COUNT(DISTINCT(u_id))
FROM transfers
WHERE send_amount_currency = 'CFA';
--'Distinct' is used to make sure duplicates are not selected incase there are any


-- agents transactions done in 2018 grouped according to months
SELECT count(when_created),EXTRACT(month from when_created) as month_of_year,
-- adding the names of month
	CASE WHEN EXTRACT(month from when_created) = 1 THEN 'January'
		WHEN EXTRACT(month from when_created) = 2 THEN 'February'
		WHEN EXTRACT(month from when_created) = 3 THEN 'March'
		WHEN EXTRACT(month from when_created) = 4 THEN 'April'
		WHEN EXTRACT(month from when_created) = 5 THEN 'May'
		WHEN EXTRACT(month from when_created) = 6 THEN 'June'
		WHEN EXTRACT(month from when_created) = 7 THEN 'July'
		WHEN EXTRACT(month from when_created) = 8 THEN 'August'
		WHEN EXTRACT(month from when_created) = 9 THEN 'September'
		WHEN EXTRACT(month from when_created) = 10 THEN 'October'
		WHEN EXTRACT(month from when_created) = 11 THEN 'November'
		WHEN EXTRACT(month from when_created) = 12 THEN 'December'
	END AS name_of_month
FROM agent_transactions
WHERE when_created BETWEEN '2018-01-01' AND '2018-12-31'
GROUP BY month_of_year
ORDER BY month_of_year asc;
/* the query above counts dates when transactions are created 
	from the when_created(when transactions are created) column in 2018
	and groups them according to the months in the year */


/* grouping and counting wave agents as net depositors
or net withdrawals based on the net sum of amount they
at the end of the week */
SELECT DISTINCT(net_spend),
	COUNT(*) AS total_number
FROM
	(
	SELECT DISTINCT(agent_id),
		CASE WHEN SUM(amount) < 0 THEN 'Net withdrawer'
			WHEN SUM(amount) > 0 THEN 'Net depositor'
		END AS net_spend
	FROM agent_transactions
	WHERE when_created >= NOW() - interval '1 week'
	GROUP BY agent_id 
	ORDER BY net_spend asc
/* The nested select statement classifies all the different agent
into whether they are net withdrwers or net depositors based  on 
their net spending within the week */
	)
AS net_spend
GROUP BY net_spend;
/*The outer select statement count the total number in each 
category*/



-- Creating table for employees hired within the week
CREATE TABLE atx_volume_city_summary
AS
	SELECT count(atx_id) AS total_recent_atx,agents.city 
	FROM agent_transactions AS atx
		LEFT JOIN agents
		ON atx.agent_id = agents.agent_id
	
	/*left join because i don't want to create a record that may
	not have some agent transaction records */
	
	WHERE atx.when_created >= NOW() - interval '1 week'
	GROUP BY city
	ORDER BY city; -- to make locating records easier
-- Created table because questions said to create a table




-- Expanding atx volume to include country
CREATE TABLE atx_volume_country_summary
AS
	SELECT count(atx_id) AS total_recent_atx,agents.city,agents.country 
	FROM agent_transactions AS atx
		LEFT JOIN agents
		ON atx.agent_id = agents.agent_id
	
	/*left join because i don't want to create a record that may
	not have some agent transaction records */
	
	WHERE atx.when_created >= NOW() - interval '1 week'
	GROUP BY agents.country,agents.city
	ORDER BY agents.country,agents.city; -- to make locating records easier

--table created because questions hints to answering like question 6



--Building (creating) a send volume by country and kind table
CREATE TABLE send_volume_by_country_kind
AS
	SELECT COUNT(send_amount_scalar) AS volume, --rem to change to volume
		tr.kind,
		wallets.ledger_location AS country --Aliased to suit question deliverables
	FROM transfers AS tr
		LEFT JOIN wallets
		ON tr.source_wallet_id = wallets.wallet_id
	
	/*My thought process is all source_wallet_id are wallets_id and they are 
	named as such because they have been used to make a sending transaction */
	
	WHERE tr.when_created >= NOW() - interval '1 week'
	GROUP BY wallets.ledger_location, tr.kind
	ORDER BY wallets.ledger_location, tr.kind;  --to make locating records easier


CREATE TABLE update_volume_country_kind_summary
	(
		transaction_count integer NOT NULL,
	 number_of_unique_senders integer NOT NULL
 )
INHERITS(send_volume_by_country_kind);
/*New table must inherit properties of table in Q8 */


-- Wallets that have done transactions over 10 million CFA in the last month
SELECT DISTINCT(source_wallet_id),
	COUNT(source_wallet_id) AS total_wallet_transactions,
	SUM(send_amount_scalar) AS total_amount
FROM transfers
WHERE when_created >= NOW() - interval '1 month'
	AND send_amount_currency = 'CFA'
	/*The send_amount_currency condition is included to ensure that only
	transactions made in CFA are considered and summed */
GROUP BY source_wallet_id
HAVING SUM(send_amount_scalar) > 10000000  
ORDER BY source_wallet_id asc; -- for easy identification of records
	/*My understanding was to identify the differnt number of times
	a source_wallet_id had made a transaction in CFA within the month,
	add all and select source_wallet_id whose transactions are more than
	10,000,000*/


