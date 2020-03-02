﻿CREATE PROCEDURE [procfwk].[AddProperty]
	(
	@PropertyName VARCHAR(128),
	@PropertyValue NVARCHAR(500),
	@Description NVARCHAR(MAX) = NULL
	)
AS

SET NOCOUNT ON;

BEGIN

	;WITH sourceTable AS
		(
		SELECT
			@PropertyName AS 'PropertyName',
			@PropertyValue AS 'PropertyValue',
			@Description AS 'Description',
			GETDATE() AS 'StartEndDate'
		)
	--insert new version of existing property from MERGE OUTPUT
	INSERT INTO [procfwk].[Properties]
		(
		[PropertyName],
		[PropertyValue],
		[Description],
		[ValidFrom]
		)
	SELECT
		[PropertyName],
		[PropertyValue],
		[Description],
		GETDATE()
	FROM
		(
		MERGE INTO
			[procfwk].[Properties] targetTable
		USING
			sourceTable
				ON sourceTable.[PropertyName] = targetTable.[PropertyName]	
		--set valid to date on existing property
		WHEN MATCHED AND [ValidTo] IS NULL THEN 
			UPDATE
			SET
				targetTable.[ValidTo] = sourceTable.[StartEndDate]
		--add new property
		WHEN NOT MATCHED BY TARGET THEN
			INSERT
				(
				[PropertyName],
				[PropertyValue],
				[Description],
				[ValidFrom]
				)
			VALUES
				(
				sourceTable.[PropertyName],
				sourceTable.[PropertyValue],
				sourceTable.[Description],
				sourceTable.[StartEndDate]
				)
			--for new entry of existing record
			OUTPUT
				$action AS 'Action',
				sourceTable.*
			) AS MergeOutput
		WHERE
			MergeOutput.[Action] = 'UPDATE'

END