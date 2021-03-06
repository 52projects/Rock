-- Hotfix 006
    DECLARE @AttributeId INT = ( SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = '3D24A4D2-90AF-4FDD-8CE2-7D1F9B76104B' )
    UPDATE [AttributeValue] 
	SET [value] = '67bd09b0-0c6e-44e7-a8eb-0e71551f3e6b'
	WHERE [AttributeId] = @AttributeId

    SET @AttributeId = ( SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = '39D260A5-A976-4DA9-B3E0-7381E9B8F3D5' )
    UPDATE [AttributeValue] 
	SET [value] = 'a1cbdaa4-94dd-4156-8260-5a3781e39fd0'
	WHERE [AttributeId] = @AttributeId


-- Hotfix 007
    DECLARE @GroupEntityTypeId int = ( SELECT TOP 1 [Id] FROM [EntityType] WHERE [Guid] = '9BBFDA11-0D22-40D5-902F-60ADFBC88987' )
    DECLARE @BinaryFileEntityTypeId int = (SELECT TOP 1 [Id] FROM [EntityType] WHERE [Guid] = '62AF597F-F193-412B-94EA-291CF713327D')
    
    DECLARE @BackgroundCheckFileTypeId int = (SELECT TOP 1 [Id] FROM [BinaryFileType] WHERE [Guid] = '5C701472-8A6B-4BBE-AEC6-EC833C859F2D')

    DECLARE @AdminRoleId int = ( SELECT TOP 1 [Id] FROM [Group] WHERE [Guid] = '628C51A8-4613-43ED-A18D-4A6FB999273E' )
	DECLARE @StaffRoleId int = ( SELECT TOP 1 [Id] FROM [Group] WHERE [Guid] = '2C112948-FF4C-46E7-981A-0257681EADF4' )
	DECLARE @StaffLikeRoleId int = ( SELECT TOP 1 [Id] FROM [Group] WHERE [Guid] = '300BA2C8-49A3-44BA-A82A-82E3FD8C3745' )
    DECLARE @SafetyRoleId int = (SELECT TOP 1 [Id] FROM [Group] WHERE [Guid] = '32E80B6C-A1EB-40FD-BEC3-E11DE8FF75AB')

    IF NOT EXISTS ( 
	    SELECT [Id] 
	    FROM [Auth]
	    WHERE [EntityTypeId] = @GroupEntityTypeId
	    AND [EntityId] = 0
	    AND [Action] = 'View'
    )
    BEGIN

	    INSERT INTO [dbo].[Auth] ( [EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid] )
	    VALUES ( @GroupEntityTypeId, 0, 0, 'View', 'A', 0, @AdminRoleId, NEWID() )

	    INSERT INTO [dbo].[Auth] ( [EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid] )
	    VALUES ( @GroupEntityTypeId, 0, 1, 'View', 'A', 0, @StaffRoleId, NEWID() )

	    INSERT INTO [dbo].[Auth] ( [EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid] )
	    VALUES ( @GroupEntityTypeId, 0, 2, 'View', 'A', 0, @StaffLikeRoleId, NEWID() )

	    INSERT INTO [dbo].[Auth] ( [EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [Guid] )
	    VALUES ( @GroupEntityTypeId, 0, 3, 'View', 'D', 1, NEWID() )

    END

    IF NOT EXISTS ( 
	    SELECT [Id] 
	    FROM [Auth]
	    WHERE [EntityTypeId] = @BinaryFileEntityTypeId
	    AND [EntityId] = @BackgroundCheckFileTypeId
	    AND [Action] = 'View'
    )
    BEGIN

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'View', 'A', 0, @SafetyRoleId, newid())

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'View', 'A', 0, @AdminRoleId, newid())

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'View', 'D', 1, null, newid())

    END

    IF NOT EXISTS ( 
	    SELECT [Id] 
	    FROM [Auth]
	    WHERE [EntityTypeId] = @BinaryFileEntityTypeId
	    AND [EntityId] = @BackgroundCheckFileTypeId
	    AND [Action] = 'Edit'
    )
    BEGIN

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'Edit', 'A', 0, @SafetyRoleId, newid())

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'Edit', 'A', 0, @AdminRoleId, newid())

        INSERT INTO [Auth] ([EntityTypeId], [EntityId], [Order], [Action], [AllowOrDeny], [SpecialRole], [GroupId], [Guid])
        VALUES (@BinaryFileEntityTypeId, @BackgroundCheckFileTypeId, 0, 'Edit', 'D', 1, null, newid())

    END


-- Hotfix 008
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spCrm_FamilyAnalyticsAttendance]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[spCrm_FamilyAnalyticsAttendance]

GO
/*
<doc>
	<summary>
 		This stored procedure updates several attributes related to a person's
		attendance.
	</summary>
	
	<remarks>	
		For eRA we only consider adults for the critieria.
	</remarks>
	<code>
		EXEC [dbo].[spCrm_FamilyAnalyticsAttendance] 
	</code>
</doc>
*/

CREATE PROCEDURE [dbo].[spCrm_FamilyAnalyticsAttendance]

AS
BEGIN
	
	-- configuration of the duration in weeks
	DECLARE @EntryAttendanceDurationWeeks int = 16
		
	DECLARE @cACTIVE_RECORD_STATUS_VALUE_GUID uniqueidentifier = '618F906C-C33D-4FA3-8AEF-E58CB7B63F1E'
	DECLARE @cPERSON_RECORD_TYPE_VALUE_GUID uniqueidentifier = '36CF10D6-C695-413D-8E7C-4546EFEF385E'
	DECLARE @cATTRIBUTE_IS_ERA_GUID uniqueidentifier = 'CE5739C5-2156-E2AB-48E5-1337C38B935E'
	DECLARE @cFAMILY_GROUPTYPE_GUID uniqueidentifier = '790E3215-3B10-442B-AF69-616C0DCB998E'
	DECLARE @cADULT_ROLE_GUID uniqueidentifier = '2639F9A5-2AAE-4E48-A8C3-4FFE86681E42'
	DECLARE @cCHILD_ROLE_GUID uniqueidentifier = 'C8B1814F-6AA7-4055-B2D7-48FE20429CB9'

	DECLARE @cATTRIBUTE_FIRST_ATTENDED uniqueidentifier  = 'AB12B3B0-55B8-D6A5-4C1F-DB9CCB2C4342'
	DECLARE @cATTRIBUTE_LAST_ATTENDED uniqueidentifier  = '5F4C6462-018E-D19C-4AB0-9843CB21C57E'
	DECLARE @cATTRIBUTE_TIMES_ATTENDED_IN_DURATION uniqueidentifier  = '45A1E978-DC5B-CFA1-4AF4-EA098A24C914'

	-- --------- END CONFIGURATION --------------

	DECLARE @ActiveRecordStatusValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cACTIVE_RECORD_STATUS_VALUE_GUID)
	DECLARE @PersonRecordTypeValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cPERSON_RECORD_TYPE_VALUE_GUID)
	DECLARE @IsEraAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_IS_ERA_GUID)
	DECLARE @FamilyGroupTypeId int = (SELECT TOP 1 [Id] FROM [GroupType] WHERE [Guid] = @cFAMILY_GROUPTYPE_GUID)
	DECLARE @AdultRoleId int = (SELECT TOP 1 [Id] FROM [GroupTypeRole] WHERE [Guid] = @cADULT_ROLE_GUID)
	DECLARE @ChildRoleId int = (SELECT TOP 1 [Id] FROM [GroupTypeRole] WHERE [Guid] = @cCHILD_ROLE_GUID)

	-- calculate dates for query
	DECLARE @SundayDateStart datetime = [dbo].[ufnUtility_GetPreviousSundayDate]()
	DECLARE @SundayEntryAttendanceDuration datetime = DATEADD(DAY,  (7 * @EntryAttendanceDurationWeeks * -1), @SundayDateStart)
	


	-- first checkin
	DECLARE @FirstAttendedAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_FIRST_ATTENDED)
	DELETE FROM [AttributeValue] WHERE [AttributeId] = @FirstAttendedAttributeId;

	WITH
	  cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	  AS
	  (
		SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		FROM [Person] p
		CROSS APPLY
			(
			SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			FROM    
				[GroupMember] gm 
				INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			WHERE 
				gm.[PersonId] = p.[Id] 
			) fr
		WHERE
			[RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	  )
	INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	SELECT * FROM 
		(SELECT 
			i.[PersonId]
			, @FirstAttendedAttributeId AS [AttributeId]
			, CASE WHEN [FamilyRole] = 'Adult' THEN 
					(SELECT 
						MIN(a.StartDateTime )
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] IN (SELECT [Id] FROM [dbo].[ufnCrm_FamilyMembersOfPersonId](i.[PersonId])))
				ELSE
					(SELECT 
						MIN(a.StartDateTime )
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] = i.[PersonId])
			  END AS [FirstAttendedDate]
			, 0 AS [IsSystem]
			, newid() AS [Guid]
			, getdate() AS [CreateDate]
		FROM cteIndividual i ) AS a
	WHERE a.[FirstAttendedDate] IS NOT NULL

	-- last checkin
	DECLARE @LastAttendedAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_LAST_ATTENDED)
	DELETE FROM [AttributeValue] WHERE [AttributeId] = @LastAttendedAttributeId;

	WITH
	  cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	  AS
	  (
		SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		FROM [Person] p
		CROSS APPLY
			(
			SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			FROM    
				[GroupMember] gm 
				INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			WHERE 
				gm.[PersonId] = p.[Id] 
			) fr
		WHERE
			[RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	  )
	INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	SELECT * FROM 
		(SELECT 
			i.[PersonId]
			, @LastAttendedAttributeId AS [AttributeId]
			, CASE WHEN [FamilyRole] = 'Adult' THEN 
					(SELECT 
						MAX(a.StartDateTime )
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] IN (SELECT [Id] FROM [dbo].[ufnCrm_FamilyMembersOfPersonId](i.[PersonId])))
				ELSE
					(SELECT 
						MAX(a.StartDateTime )
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] = i.[PersonId])
			  END AS [LastAttendedDate]
			, 0 AS [IsSystem]
			, newid() AS [Guid]
			, getdate() AS [CreateDate]
		FROM cteIndividual i ) AS a
	WHERE a.[LastAttendedDate] IS NOT NULL

	-- times checkedin
	DECLARE @TimesAttendedAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_TIMES_ATTENDED_IN_DURATION)
	DELETE FROM [AttributeValue] WHERE [AttributeId] = @TimesAttendedAttributeId;

	WITH
	  cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	  AS
	  (
		SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		FROM [Person] p
		CROSS APPLY
			(
			SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			FROM    
				[GroupMember] gm 
				INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			WHERE 
				gm.[PersonId] = p.[Id] 
			) fr
		WHERE
			[RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	  )
	INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	SELECT * FROM 
		(SELECT 
			i.[PersonId]
			, @TimesAttendedAttributeId AS [AttributeId]
			, CASE WHEN [FamilyRole] = 'Adult' THEN 
					(SELECT 
						COUNT(*)
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
						AND CAST( a.[StartDateTime] AS DATE ) <= @SundayDateStart AND a.[StartDateTime] >= @SundayEntryAttendanceDuration
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] IN (SELECT [Id] FROM [dbo].[ufnCrm_FamilyMembersOfPersonId](i.[PersonId])))
				ELSE
					(SELECT 
						COUNT(*)
					FROM
						[Attendance] a
						INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
					WHERE 
						[GroupId] IN (SELECT [Id] FROM [dbo].[ufnCheckin_WeeklyServiceGroups]())
						AND CAST( a.[StartDateTime] AS DATE ) <= @SundayDateStart AND a.[StartDateTime] >= @SundayEntryAttendanceDuration
                        AND a.[DidAttend] = 1
						AND pa.[PersonId] = i.[PersonId])
			  END AS [CheckinCount]
			, 0 AS [IsSystem]
			, newid() AS [Guid]
			, getdate() AS [CreateDate]
		FROM cteIndividual i ) AS a
	WHERE a.[CheckinCount] IS NOT NULL

	
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spCrm_FamilyAnalyticsEraDataset]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[spCrm_FamilyAnalyticsEraDataset]
GO

/*
<doc>
	<summary>
 		This stored procedure returns a data set used by the Rock eRA job to add/remove
		people from being an eRA. It should not be modified as it will be updated in the
		future to meet additional requirements.

		The goal of the query is to return both those that meet the eRA requirements as well
		as those that are marked as already being an eRA and the criteria to ensure that
		they still should be an era.
	</summary>
	
	<remarks>	
		For eRA we only consider adults for the critieria.
	</remarks>
	<code>
		EXEC [dbo].[spCrm_FamilyAnalyticsEraDataset] 
	</code>
</doc>
*/

CREATE PROCEDURE [dbo].[spCrm_FamilyAnalyticsEraDataset]
	
AS
BEGIN
	
	-- configuration of the duration in weeks
	DECLARE @EntryGivingDurationLongWeeks int = 52
	DECLARE @EntryGivingDurationShortWeeks int = 6
	DECLARE @EntryAttendanceDurationWeeks int = 16
	DECLARE @ExitGivingDurationWeeks int = 8
	DECLARE @ExitAttendanceDurationShortWeeks int = 4
	DECLARE @ExitAttendanceDurationLongWeeks int = 16

	-- configuration of the item counts in the durations
	DECLARE @EntryGiftCountDurationLong int = 4
	DECLARE @EntryGiftCountDurationShort int = 1
	DECLARE @EntryAttendanceCountDuration int = 8
	
	DECLARE @cACTIVE_RECORD_STATUS_VALUE_GUID uniqueidentifier = '618F906C-C33D-4FA3-8AEF-E58CB7B63F1E'
	DECLARE @cPERSON_RECORD_TYPE_VALUE_GUID uniqueidentifier = '36CF10D6-C695-413D-8E7C-4546EFEF385E'
	DECLARE @cATTRIBUTE_IS_ERA_GUID uniqueidentifier = 'CE5739C5-2156-E2AB-48E5-1337C38B935E'
	DECLARE @cFAMILY_GROUPTYPE_GUID uniqueidentifier = '790E3215-3B10-442B-AF69-616C0DCB998E'
	DECLARE @cADULT_ROLE_GUID uniqueidentifier = '2639F9A5-2AAE-4E48-A8C3-4FFE86681E42'
	DECLARE @cTRANSACTION_TYPE_CONTRIBUTION uniqueidentifier = '2D607262-52D6-4724-910D-5C6E8FB89ACC';

	-- --------- END CONFIGURATION --------------

	DECLARE @ActiveRecordStatusValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cACTIVE_RECORD_STATUS_VALUE_GUID)
	DECLARE @PersonRecordTypeValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cPERSON_RECORD_TYPE_VALUE_GUID)
	DECLARE @IsEraAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_IS_ERA_GUID)
	DECLARE @FamilyGroupTypeId int = (SELECT TOP 1 [Id] FROM [GroupType] WHERE [Guid] = @cFAMILY_GROUPTYPE_GUID)
	DECLARE @AdultRoleId int = (SELECT TOP 1 [Id] FROM [GroupTypeRole] WHERE [Guid] = @cADULT_ROLE_GUID)
	DECLARE @ContributionType int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cTRANSACTION_TYPE_CONTRIBUTION)

	-- calculate dates for query
	DECLARE @SundayDateStart datetime = [dbo].[ufnUtility_GetPreviousSundayDate]()
	DECLARE @SundayEntryGivingDurationLong datetime = DATEADD(DAY,  (7 * @EntryGivingDurationLongWeeks * -1), @SundayDateStart)
	DECLARE @SundayEntryGivingDurationShort datetime = DATEADD(DAY,  (7 * @EntryGivingDurationShortWeeks * -1), @SundayDateStart)
	DECLARE @SundayEntryAttendanceDuration datetime = DATEADD(DAY,  (7 * @EntryAttendanceDurationWeeks * -1), @SundayDateStart)

	DECLARE @SundayExitGivingDuration datetime = DATEADD(DAY, (7 * @ExitGivingDurationWeeks * -1), @SundayDateStart)
	DECLARE @SundayExitAttendanceDurationShort datetime = DATEADD(DAY,  (7 * @ExitAttendanceDurationShortWeeks * -1), @SundayDateStart)
	DECLARE @SundayExitAttendanceDurationLong datetime = DATEADD(DAY,  (7 * @ExitAttendanceDurationLongWeeks * -1), @SundayDateStart)
	

	SELECT
		[FamilyId]
		, MAX([EntryGiftCountDurationShort]) AS [EntryGiftCountDurationShort]
		, MAX([EntryGiftCountDurationLong]) AS [EntryGiftCountDurationLong]
		, MAX([ExitGiftCountDuration]) AS [ExitGiftCountDuration]
		, MAX([EntryAttendanceCountDuration]) AS [EntryAttendanceCountDuration]
		, MAX([ExitAttendanceCountDurationShort]) AS [ExitAttendanceCountDurationShort]
		, MAX([ExitAttendanceCountDurationLong]) AS [ExitAttendanceCountDurationLong]
		, CAST(MAX([IsEra]) AS BIT) AS [IsEra]
	FROM (
		SELECT 
			p.[Id]
			, CASE WHEN (era.[Value] = 'true') THEN 1  ELSE 0 END AS [IsEra]
			, g.[Id] AS [FamilyId]
			, (SELECT COUNT(DISTINCT(ft.[Id])) 
					FROM [FinancialTransaction] ft
						INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
						INNER JOIN [Person] g1 ON g1.[Id] = pa.[PersonId]
						INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
						INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
					WHERE 
						ft.TransactionTypeValueId = @ContributionType
						AND ft.TransactionDateTime >= @SundayEntryGivingDurationShort
						AND ft.TransactionDateTime <= @SundayDateStart
						AND ( g1.[Id] = p.[Id] OR ( g1.[GivingGroupId] IS NOT NULL AND g1.[GivingGroupID] = p.[GivingGroupId] ) )
						AND fa.[IsTaxDeductible] = 1) AS [EntryGiftCountDurationShort]
			, (SELECT COUNT(DISTINCT(ft.[Id])) 
					FROM [FinancialTransaction] ft
						INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
						INNER JOIN [Person] g1 ON g1.[Id] = pa.[PersonId]
						INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
						INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
					WHERE 
						ft.TransactionTypeValueId = @ContributionType
						AND ft.TransactionDateTime >= @SundayExitGivingDuration
						AND ft.TransactionDateTime <= @SundayDateStart
						AND ( g1.[Id] = p.[Id] OR ( g1.[GivingGroupId] IS NOT NULL AND g1.[GivingGroupID] = p.[GivingGroupId] ) )
						AND fa.[IsTaxDeductible] = 1) AS [ExitGiftCountDuration]	
			, (SELECT COUNT(DISTINCT(ft.[Id])) 
					FROM [FinancialTransaction] ft
						INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
						INNER JOIN [Person] g1 ON g1.[Id] = pa.[PersonId]
						INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
						INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
					WHERE 
						ft.TransactionTypeValueId = @ContributionType
						AND ft.TransactionDateTime >= @SundayEntryGivingDurationLong
						AND ft.TransactionDateTime <= @SundayDateStart
						AND ( g1.[Id] = p.[Id] OR ( g1.[GivingGroupId] IS NOT NULL AND g1.[GivingGroupID] = p.[GivingGroupId] ) )
						AND fa.[IsTaxDeductible] = 1) AS [EntryGiftCountDurationLong]	
			, (SELECT 
					COUNT(DISTINCT a.SundayDate )
				FROM
					[Attendance] a
					INNER JOIN [Group] ag ON ag.[Id] = a.[GroupId]
					INNER JOIN [GroupType] agt ON agt.[Id] = ag.[GroupTypeId] AND agt.[AttendanceCountsAsWeekendService] = 1
					INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
				WHERE 
					pa.[PersonId] IN (SELECT [PersonId] FROM [GroupMember] WHERE [GroupId] = g.[Id] ) 
                    AND a.[DidAttend] = 1
					AND a.[StartDateTime] <= @SundayDateStart AND a.[StartDateTime] >= @SundayExitAttendanceDurationShort) AS [ExitAttendanceCountDurationShort]
			, (SELECT 
					COUNT(DISTINCT a.SundayDate )
				FROM
					[Attendance] a
					INNER JOIN [Group] ag ON ag.[Id] = a.[GroupId]
					INNER JOIN [GroupType] agt ON agt.[Id] = ag.[GroupTypeId] AND agt.[AttendanceCountsAsWeekendService] = 1
					INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
				WHERE 
					pa.[PersonId] IN (SELECT [PersonId] FROM [GroupMember] WHERE [GroupId] = g.[Id] ) 
                    AND a.[DidAttend] = 1
					AND a.[StartDateTime] <= @SundayDateStart AND a.[StartDateTime] >= @SundayEntryAttendanceDuration) AS [EntryAttendanceCountDuration]
			, (SELECT 
					COUNT(DISTINCT a.SundayDate )
				FROM
					[Attendance] a
					INNER JOIN [Group] ag ON ag.[Id] = a.[GroupId]
					INNER JOIN [GroupType] agt ON agt.[Id] = ag.[GroupTypeId] AND agt.[AttendanceCountsAsWeekendService] = 1
					INNER JOIN [PersonAlias] pa ON pa.[Id] = a.[PersonAliasId]
				WHERE 
					pa.[PersonId] IN (SELECT [PersonId] FROM [GroupMember] WHERE [GroupId] = g.[Id] ) 
                    AND a.[DidAttend] = 1
					AND a.[StartDateTime] <= @SundayDateStart AND a.[StartDateTime] >= @SundayExitAttendanceDurationLong) AS [ExitAttendanceCountDurationLong]	
		FROM
			[Person] p
			INNER JOIN [GroupMember] gm ON gm.[PersonId] = p.[Id] AND gm.[GroupRoleId] = @AdultRoleId
			INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
			LEFT OUTER JOIN [AttributeValue] era ON era.[EntityId] = p.[Id] AND era.[AttributeId] = @IsEraAttributeId
		WHERE
			[RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
		) AS t
		WHERE (
			([IsEra] = 1)
			OR (
				( [EntryGiftCountDurationLong] >= @EntryGiftCountDurationLong AND [EntryGiftCountDurationShort] >= @EntryGiftCountDurationShort )
				OR
				( [EntryAttendanceCountDuration] >= @EntryAttendanceCountDuration )
			)
		)
		GROUP BY [FamilyId]
	
END

GO


-- Hotfix 009
DECLARE @GroupTypeEntityTypeId int = ( SELECT TOP 1 [Id] FROM [EntityType] WHERE [Name] = 'Rock.Model.GroupType' )
DECLARE @CheckInTemplatePurposeId int = ( SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = '4A406CB0-495B-4795-B788-52BDFDE00B01' )
IF @GroupTypeEntityTypeId IS NOT NULL AND @CheckInTemplatePurposeId IS NOT NULL
BEGIN

    UPDATE [Attribute] SET [EntityTypeQualifierValue] = CAST( @CheckInTemplatePurposeId AS varchar) 
    WHERE [EntityTypeId] = @GroupTypeEntityTypeId
    AND [EntityTypeQualifierColumn] = 'GroupTypePurposeValueId'
    AND [Key] LIKE 'core_checkin_%'

END


-- Hotfix 010
    IF object_id('[dbo].[ufnCrm_GetSpousePersonIdFromPersonId]') IS NOT NULL
    BEGIN
      DROP FUNCTION [dbo].[ufnCrm_GetSpousePersonIdFromPersonId]
    END
GO
    /*
    <doc>
	    <summary>
 		    This function returns the most likely spouse for the person [Id] provided
	    </summary>

	    <returns>
		    Person [Id] of the most likely spouse; otherwise returns NULL
	    </returns>
	    <remarks>
		

	    </remarks>
	    <code>
		    SELECT [dbo].[ufnCrm_GetSpousePersonIdFromPersonId](3) -- Ted Decker (married) 
		    SELECT [dbo].[ufnCrm_GetSpousePersonIdFromPersonId](7) -- Ben Jones (single)
	    </code>
    </doc>
    */

    CREATE FUNCTION [dbo].[ufnCrm_GetSpousePersonIdFromPersonId] ( 
	    @PersonId INT 
    ) 
    RETURNS INT 
    AS
    BEGIN
	
	    RETURN (
		    SELECT 
			    TOP 1 S.[Id]
		    FROM 
			    [Group] F
			    INNER JOIN [GroupType] GT ON F.[GroupTypeId] = GT.[Id]
			    INNER JOIN [GroupMember] FM ON FM.[GroupId] = F.[Id]
			    INNER JOIN [Person] P ON P.[Id] = FM.[PersonId]
			    INNER JOIN [GroupTypeRole] R ON R.[Id] = FM.[GroupRoleId]
			    INNER JOIN [GroupMember] FM2 ON FM2.[GroupID] = F.[Id]
			    INNER JOIN [Person] S ON S.[Id] = FM2.[PersonId]
			    INNER JOIN [GroupTypeRole] R2 ON R2.[Id] = FM2.[GroupRoleId]
		    WHERE 
			    GT.[Guid] = '790E3215-3B10-442B-AF69-616C0DCB998E' -- Family
			    AND P.[Id] = @PersonID
			    AND R.[Guid] = '2639F9A5-2AAE-4E48-A8C3-4FFE86681E42' -- Person must be an Adult
			    AND R2.[Guid] = '2639F9A5-2AAE-4E48-A8C3-4FFE86681E42' -- Potential spouse must be an Adult
			    AND P.[MaritalStatusValueId] = 143 -- Person must be Married
			    AND S.[MaritalStatusValueId] = 143 -- Potential spouse must be Married
			    AND FM.[PersonId] != FM2.[PersonId] -- Cannot be married to yourself
			    -- In the future, we may need to implement and check a GLOBAL Attribute "BibleStrict" with this logic: 

                AND( P.[Gender] != S.[Gender] OR P.[Gender] = 0 OR S.[Gender] = 0 )-- Genders cannot match if both are known

            ORDER BY

                ABS( DATEDIFF( DAY, ISNULL( P.[BirthDate], '1/1/0001' ), ISNULL( S.[BirthDate], '1/1/0001' ) ) )-- If multiple results, choose nearest in age
			    , S.[Id]-- Sort by Id so that the same result is always returned
	    )

    END

GO

-- Hotfix 011
    UPDATE [Page]
    SET 
	    [PageTitle] = 'Request Profile Change'
	    ,[BrowserTitle] = 'Request Profile Change'
	    ,[InternalName] = 'Request Profile Change'
    WHERE
	    [Guid] = 'E1F9DE5A-CF99-4AF5-BEE6-EFC04F6DE57A'
	    AND [PageTitle] = 'Workflow Entry'
	    AND [BrowserTitle] = 'Workflow Entry'
	    AND [InternalName] = 'Workflow Entry'


-- Hotfix 012
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeDates]') AND type in (N'P', N'PC'))
        DROP PROCEDURE [dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeDates]
GO


    /*
    <doc>
	    <summary>
 		    This function returns attendee person ids and the dates they attended based on selected filter criteria
	    </summary>

	    <returns>
		    * PersonId
		    * SundayDate
		    * MonthDate
		    * Year Date
	    </returns>
	    <param name='GroupTypeId' datatype='int'>The Check-in Area Group Type Id (only attendance for this are will be included</param>
	    <param name='StartDate' datatype='datetime'>Beginning date range filter</param>
	    <param name='EndDate' datatype='datetime'>Ending date range filter</param>
	    <param name='GroupIds' datatype='varchar(max)'>Optional list of group ids to limit attendance to</param>
	    <param name='CampusIds' datatype='varchar(max)'>Optional list of campus ids to limit attendance to</param>
	    <param name='IncludeNullCampusIds' datatype='bit'>Flag indicating if attendance not tied to campus should be included</param>
	    <remarks>	
	    </remarks>
	    <code>
		    EXEC [dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeDates] '15,16,17,18,19,20,21,22', '2015-01-01 00:00:00', '2015-12-31 23:59:59', null, 0
	    </code>
    </doc>
    */

    CREATE PROCEDURE [dbo].[spCheckin_AttendanceAnalyticsQuery_AttendeeDates]
	      @GroupIds varchar(max)
	    , @StartDate datetime = NULL
	    , @EndDate datetime = NULL
	    , @CampusIds varchar(max) = NULL
	    , @IncludeNullCampusIds bit = 0
	    , @ScheduleIds varchar(max) = NULL
	    WITH RECOMPILE

    AS

    BEGIN

        -- Manipulate dates to only be those dates who's SundayDate value would fall between the selected date range ( so that sunday date does not need to be used in where clause )
	    SET @StartDate = COALESCE( DATEADD( day, ( 0 - DATEDIFF( day, CONVERT( datetime, '19000101', 112 ), @StartDate ) % 7 ), CONVERT( date, @StartDate ) ), '1900-01-01' )
	    SET @EndDate = COALESCE( DATEADD( day, ( 0 - DATEDIFF( day, CONVERT( datetime, '19000107', 112 ), @EndDate ) % 7 ), @EndDate ), '2100-01-01' )
        IF @EndDate < @StartDate SET @EndDate = DATEADD( day, 6 + DATEDIFF( day, @EndDate, @StartDate ), @EndDate )
	    SET @EndDate = DATEADD( second, -1, DATEADD( day, 1, @EndDate ) )

	    -- Get all the attendance
	    SELECT 
		    PA.[PersonId],
		    A.[SundayDate],
		    DATEADD( day, -( DATEPART( day, [SundayDate] ) ) + 1, [SundayDate] ) AS [MonthDate],
		    DATEADD( day, -( DATEPART( dayofyear, [SundayDate] ) ) + 1, [SundayDate] ) AS [YearDate]
	    FROM (
		    SELECT 
			    [PersonAliasId],
			    [GroupId],
			    [CampusId],
			    DATEADD( day, ( 6 - ( DATEDIFF( day, CONVERT( datetime, '19000101', 112 ), [StartDateTime] ) % 7 ) ), CONVERT( date, [StartDateTime] ) ) AS [SundayDate]
		    FROM [Attendance] A
            WHERE A.[GroupId] in ( SELECT * FROM ufnUtility_CsvToTable( @GroupIds ) ) 
            AND [StartDateTime] BETWEEN @StartDate AND @EndDate
		    AND [DidAttend] = 1
		    AND ( 
			    ( @CampusIds IS NULL OR A.[CampusId] in ( SELECT * FROM ufnUtility_CsvToTable( @CampusIds ) ) ) OR  
			    ( @IncludeNullCampusIds = 1 AND A.[CampusId] IS NULL ) 
		    )
		    AND ( @ScheduleIds IS NULL OR A.[ScheduleId] IN ( SELECT * FROM ufnUtility_CsvToTable( @ScheduleIds ) ) )
	    ) A 
	    INNER JOIN [PersonAlias] PA ON PA.[Id] = A.[PersonAliasId]

    END

GO


-- Hotfix 013
    -- Fix issue #1828
    UPDATE [SystemEmail] SET
        [To] = ''
    WHERE [Guid] = 'BC490DD4-ABBB-7DBA-4A9E-74F07F4B5881' 
        AND [To] = 'alisha@rocksolidchurchdemo.com'


-- Hotfix 014
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spCrm_FamilyAnalyticsGiving]') AND type in (N'P', N'PC'))
    BEGIN
      DROP PROCEDURE [dbo].[spCrm_FamilyAnalyticsGiving]
    END
GO

    /*
    <doc>
	    <summary>
 		    This stored procedure updates several attributes related to a person's
		    giving.
	    </summary>
	
	    <remarks>	
		    For eRA we only consider adults for the critieria.
	    </remarks>
	    <code>
		    EXEC [dbo].[spCrm_FamilyAnalyticsGiving] 
	    </code>
    </doc>
    */

    CREATE PROCEDURE [dbo].[spCrm_FamilyAnalyticsGiving]
	
    AS
    BEGIN
	
	    -- configuration of the duration in weeks
	    DECLARE @GivingDurationLongWeeks int = 52
	    DECLARE @GivingDurationShortWeeks int = 6
	
	    DECLARE @cACTIVE_RECORD_STATUS_VALUE_GUID uniqueidentifier = '618F906C-C33D-4FA3-8AEF-E58CB7B63F1E'
	    DECLARE @cPERSON_RECORD_TYPE_VALUE_GUID uniqueidentifier = '36CF10D6-C695-413D-8E7C-4546EFEF385E'
	    DECLARE @cFAMILY_GROUPTYPE_GUID uniqueidentifier = '790E3215-3B10-442B-AF69-616C0DCB998E'
	    DECLARE @cADULT_ROLE_GUID uniqueidentifier = '2639F9A5-2AAE-4E48-A8C3-4FFE86681E42'

	    DECLARE @cATTRIBUTE_FIRST_GAVE uniqueidentifier  = 'EE5EC76A-D4B9-56B5-4B48-29627D945F10'
	    DECLARE @cATTRIBUTE_LAST_GAVE uniqueidentifier  = '02F64263-E290-399E-4487-FC236F4DE81F'
	    DECLARE @cATTRIBUTE_GIFT_COUNT_SHORT uniqueidentifier  = 'AC11EF53-AE55-79A0-4CAD-43721750E988'
	    DECLARE @cATTRIBUTE_GIFT_COUNT_LONG uniqueidentifier  = '57700E8F-ED11-D787-415A-04DDF411BB10'

	    -- --------- END CONFIGURATION --------------

	    DECLARE @ActiveRecordStatusValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cACTIVE_RECORD_STATUS_VALUE_GUID)
	    DECLARE @PersonRecordTypeValueId int = (SELECT TOP 1 [Id] FROM [DefinedValue] WHERE [Guid] = @cPERSON_RECORD_TYPE_VALUE_GUID)
	    DECLARE @FamilyGroupTypeId int = (SELECT TOP 1 [Id] FROM [GroupType] WHERE [Guid] = @cFAMILY_GROUPTYPE_GUID)
	    DECLARE @AdultRoleId int = (SELECT TOP 1 [Id] FROM [GroupTypeRole] WHERE [Guid] = @cADULT_ROLE_GUID)

	
	    -- calculate dates for queries
	    DECLARE @SundayDateStart datetime = [dbo].[ufnUtility_GetPreviousSundayDate]()
	    DECLARE @SundayGivingDurationLong datetime = DATEADD(DAY,  (7 * @GivingDurationLongWeeks * -1), @SundayDateStart)
	    DECLARE @SundayGivingDurationShort datetime = DATEADD(DAY,  (7 * @GivingDurationShortWeeks * -1), @SundayDateStart);


	    -- first gift (people w/Giving Group)
	    DECLARE @FirstGaveAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_FIRST_GAVE)
	    DELETE FROM [AttributeValue] WHERE [AttributeId] = @FirstGaveAttributeId;

	    WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NOT NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @FirstGaveAttributeId AS [AttributeId]
			    , (SELECT MIN(ft.TransactionDateTime)
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[GivingGroupId] = i.[GivingGroupId]
							    AND fa.[IsTaxDeductible] = 'true') AS [FirstContributionDate]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[FirstContributionDate] IS NOT NULL

	    -- first gift (people WITHOUT Giving Group)
	    ;WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @FirstGaveAttributeId AS [AttributeId]
			    , (SELECT MIN(ft.TransactionDateTime)
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[Id] = i.[PersonId] -- match by person id
							    AND fa.[IsTaxDeductible] = 'true') AS [FirstContributionDate]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[FirstContributionDate] IS NOT NULL
	
	    -- last gift (people w/Giving Group)
	    DECLARE @LastGaveAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_LAST_GAVE)
	    DELETE FROM [AttributeValue] WHERE [AttributeId] = @LastGaveAttributeId;

	    WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NOT NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @LastGaveAttributeId AS [AttributeId]
			    , (SELECT MAX(ft.TransactionDateTime)
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[GivingGroupId] = i.[GivingGroupId]
							    AND fa.[IsTaxDeductible] = 'true') AS [LastContributionDate]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[LastContributionDate] IS NOT NULL

	    -- last gift (people WITHOUT Giving Group)
	    ;WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] -- match by person id
				    AND p.[GivingGroupId] IS NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @LastGaveAttributeId AS [AttributeId]
			    , (SELECT MAX(ft.TransactionDateTime)
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[Id] = i.[PersonId]
							    AND fa.[IsTaxDeductible] = 'true') AS [LastContributionDate]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[LastContributionDate] IS NOT NULL

	    -- number of gifts short duration (people w/Giving Group)
	    DECLARE @GiftCountShortAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_GIFT_COUNT_SHORT)
	    DELETE FROM [AttributeValue] WHERE [AttributeId] = @GiftCountShortAttributeId;

	    WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NOT NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @GiftCountShortAttributeId AS [AttributeId]
			    , (SELECT COUNT(DISTINCT(ft.[Id])) 
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[GivingGroupId] = i.[GivingGroupId]
							    AND fa.[IsTaxDeductible] = 'true'
							    AND ft.TransactionDateTime >= @SundayGivingDurationShort
							    AND ft.TransactionDateTime <= @SundayDateStart) AS [GiftCountDurationShort]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[GiftCountDurationShort] IS NOT NULL

	    -- number of gifts short duration (people WITHOUT Giving Group)
	    ;WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @GiftCountShortAttributeId AS [AttributeId]
			    , (SELECT COUNT(DISTINCT(ft.[Id])) 
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[Id] = i.[PersonId] -- match by person id
							    AND fa.[IsTaxDeductible] = 'true'
							    AND ft.TransactionDateTime >= @SundayGivingDurationShort
							    AND ft.TransactionDateTime <= @SundayDateStart) AS [GiftCountDurationShort]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[GiftCountDurationShort] IS NOT NULL

	    -- number of gifts long duration (people w/Giving Group)
	    DECLARE @GiftCountLongAttributeId int = (SELECT TOP 1 [Id] FROM [Attribute] WHERE [Guid] = @cATTRIBUTE_GIFT_COUNT_LONG)
	    DELETE FROM [AttributeValue] WHERE [AttributeId] = @GiftCountLongAttributeId;

	    WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NOT NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @GiftCountLongAttributeId AS [AttributeId]
			    , (SELECT COUNT(DISTINCT(ft.[Id])) 
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[GivingGroupId] = i.[GivingGroupId]
							    AND fa.[IsTaxDeductible] = 'true'
							    AND ft.TransactionDateTime >= @SundayGivingDurationLong
							    AND ft.TransactionDateTime <= @SundayDateStart) AS [GiftCountDurationLong]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[GiftCountDurationLong] IS NOT NULL
	
	    -- number of gifts long duration (people WITHOUT Giving Group)
	    ;WITH
	      cteIndividual ([PersonId], [GivingGroupId], [FamilyRole])
	      AS
	      (
		    SELECT p.[Id] AS [PersonId], p.[GivingGroupId], CASE WHEN fr.[FamilyRole] = @AdultRoleId THEN 'Adult' ELSE 'Child' END
		    FROM [Person] p
		    CROSS APPLY
			    (
			    SELECT TOP 1 gm.[GroupRoleId] AS [FamilyRole]
			    FROM    
				    [GroupMember] gm 
				    INNER JOIN [Group] g ON g.[Id] = gm.[GroupId] AND g.[GroupTypeId] = @FamilyGroupTypeId
				    INNER JOIN [GroupTypeRole] gtr ON gtr.[Id] = gm.[GroupRoleId]
			    WHERE 
				    gm.[PersonId] = p.[Id] 
				    AND p.[GivingGroupId] IS NULL
				
			    ) fr
		    WHERE
			    [RecordStatusValueId] = @ActiveRecordStatusValueId -- record is active
			    AND [RecordTypeValueId] = @PersonRecordTypeValueId  -- person record type (not business)
	      )
	    INSERT INTO AttributeValue ([EntityId], [AttributeId], [Value], [IsSystem], [Guid], [CreatedDateTime])
	    SELECT * FROM 
		    (SELECT 
			    [PersonId]
			    , @GiftCountLongAttributeId AS [AttributeId]
			    , (SELECT COUNT(DISTINCT(ft.[Id])) 
						    FROM [FinancialTransaction] ft
							    INNER JOIN [PersonAlias] pa ON pa.[Id] = ft.[AuthorizedPersonAliasId]
							    INNER JOIN [Person] gp ON gp.[Id] = pa.[PersonId]
							    INNER JOIN [FinancialTransactionDetail] ftd ON ftd.[TransactionId] = ft.[Id]
							    INNER JOIN [FinancialAccount] fa ON fa.[Id] = ftd.AccountId
						    WHERE 
							    gp.[Id] = i.[PersonId] -- match by person id
							    AND fa.[IsTaxDeductible] = 'true'
							    AND ft.TransactionDateTime >= @SundayGivingDurationLong
							    AND ft.TransactionDateTime <= @SundayDateStart) AS [GiftCountDurationLong]
			    , 0 AS [IsSystem]
			    , newid() AS [Guid]
			    , getdate() AS [CreateDate]
		    FROM cteIndividual i
		    WHERE [FamilyRole] = 'Adult') AS g
	    WHERE g.[GiftCountDurationLong] IS NOT NULL
	
    END
GO
