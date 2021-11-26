EXEC tSQLt.NewTestClass 'AnnotationNoTransactionTests';
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test runs test without transaction]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS INSERT INTO #TranCount VALUES(''I'',@@TRANCOUNT);;
  ');

  SELECT 'B' Id, @@TRANCOUNT TranCount
    INTO #TranCount;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';

  INSERT INTO #TranCount VALUES('A',@@TRANCOUNT);

  SELECT Id, TranCount-MIN(TranCount)OVER() AdjustedTrancount
    INTO #Actual
    FROM #TranCount;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected
  VALUES('B',0),('I',0),('A',0);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
  
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
--[@tSQLt:SkipTest]('TODO: needs other tests first')
CREATE PROCEDURE AnnotationNoTransactionTests.[test produces meaningful error when pre and post transactions counts don't match]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS BEGIN TRAN;
  ');

  --EXEC tSQLt.ExpectException @ExpectedMessage = 'SOMETHING RATHER', @ExpectedSeverity = NULL, @ExpectedState = NULL;

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test transaction name is NULL in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RETURN;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT TranName INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES(NULL);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test if not NoTransaction TranName is valued in TestResults table]
AS
BEGIN
  DECLARE @ActualTranName NVARCHAR(MAX);
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test should execute inside of transaction] AS RETURN;');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute inside of transaction]';
  SET @ActualTranName = (SELECT TranName FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = 'tSQLtTran%', @Actual = @ActualTranName;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test succeeding test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RETURN;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Success');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test failing test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS EXEC tSQLt.Fail ''Some Obscure Reason'';
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Failure','Some Obscure Reason');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test recoverable erroring test gets correct entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should execute outside of transaction] AS RAISERROR (''Some Obscure Recoverable Error'', 16, 10);
  ');

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test should execute outside of transaction]';
  SELECT Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('Error','Some Obscure Recoverable Error[16,10]{MyInnerTests.test should execute outside of transaction,3}');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls tSQLt.Private_CleanUp]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT FullTestName INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('[MyInnerTests].[test1]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and succeeding]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS RETURN;');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and failing]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS EXEC tSQLt.Fail;');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_CleanUp if not annotated and erroring]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE MyInnerTests.[test1] AS RAISERROR(''X'',16,10);');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp';

  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT * INTO #Actual FROM tSQLt.Private_CleanUp_SpyProcedureLog;

  EXEC tSQLt.AssertEmptyTable '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is appended to tSQLt.TestResult.Msg]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS PRINT 1/0;
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult);

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test message returned by tSQLt.Private_CleanUp is called before the test result message is printed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test1] AS RAISERROR(''<In-Test-Error>'',16,10);
  ');
 
  EXEC tSQLt.SetSummaryError 0;
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'SET @ErrorMsg = ''<Example Message>'';'; 
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_Print';

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Message FROM tSQLt.Private_Print_SpyProcedureLog WHERE Message LIKE '%<In-Test-Error>%');

  EXEC tSQLt.AssertLike @ExpectedPattern = '% <Example Message>', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test tSQLt tables are backed up before test is executed]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual SELECT Action FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  SELECT Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('Save');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test using SkipTest and NoTransaction annotation skips the test]
AS
BEGIN
  CREATE TABLE #SkippedTestExecutionLog (Id INT);
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    --[@'+'tSQLt:SkipTest]('')
    CREATE PROCEDURE MyInnerTests.[skippedTest]
    AS
    BEGIN
      INSERT INTO #SkippedTestExecutionLog VALUES (1);
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[skippedTest]';

  EXEC tSQLt.AssertEmptyTable @TableName = '#SkippedTestExecutionLog';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call 'Save' if @NoTransactionFlag=0;]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual SELECT Action FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;
    END;
  ');
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';
  SELECT TOP(0) Action INTO #Actual FROM tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog;

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  EXEC tSQLt.AssertEmptyTable @TableName = '#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not call tSQLt.Private_NoTransactionHandleTables if @NoTransactionFlag=1 and @SkipTestFlag=1]
AS
BEGIN
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_NoTransactionHandleTables';

  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    --[@'+'tSQLt:SkipTest]('''')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  EXEC tSQLt.AssertEmptyTable @TableName = 'tSQLt.Private_NoTransactionHandleTables_SpyProcedureLog';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[Redact IsTestObject status on all objects]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  WITH MarkedTestDoubles AS
  (
    SELECT 
        TempO.Name,
        SCHEMA_NAME(TempO.schema_id) SchemaName,
        TempO.type ObjectType
      FROM sys.tables TempO
      JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = TempO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = 1
  )
  SELECT @cmd = 
  (
    SELECT 
        'EXEC sp_updateextendedproperty ''tSQLt.IsTempObject'',-1342,''SCHEMA'', '''+MTD.SchemaName+''', ''TABLE'', '''+MTD.Name+''';'  
      FROM MarkedTestDoubles MTD
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[Restore IsTestObject status on all objects]
AS
BEGIN
  DECLARE @cmd NVARCHAR(MAX);
  WITH MarkedTestDoubles AS
  (
    SELECT 
        TempO.Name,
        SCHEMA_NAME(TempO.schema_id) SchemaName,
        TempO.type ObjectType
      FROM sys.tables TempO
      JOIN sys.extended_properties AS EP
        ON EP.class_desc = 'OBJECT_OR_COLUMN'
       AND EP.major_id = TempO.object_id
       AND EP.name = 'tSQLt.IsTempObject'
       AND EP.value = -1342
  )
  SELECT @cmd = 
  (
    SELECT 
        'EXEC sp_updateextendedproperty ''tSQLt.IsTempObject'',1,''SCHEMA'', '''+MTD.SchemaName+''', ''TABLE'', '''+MTD.Name+''';'  
      FROM MarkedTestDoubles MTD
       FOR XML PATH(''),TYPE
  ).value('.','NVARCHAR(MAX)');
  EXEC(@cmd);
END;
GO
CREATE FUNCTION AnnotationNoTransactionTests.PassThrough(@TestName NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN
  SELECT @TestName TestName
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[CLEANUP: test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.DropClass MyInnerTests;
END;
GO
--[@tSQLt:NoTransaction]('AnnotationNoTransactionTests.[CLEANUP: test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]')
/* This test must be NoTransaction because the inner test will invalidate any open transaction causing chaos and turmoil in the reactor. */
CREATE PROCEDURE AnnotationNoTransactionTests.[test an unrecoverable erroring test gets correct (Success/Failure but not Error) entry in TestResults table]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_GetLastTestNameIfNotProvided', @FakeFunctionName = 'AnnotationNoTransactionTests.PassThrough'; /* --<-- Prevent tSQLt-internal turmoil */
  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_SaveTestNameForSession';/* --<-- Prevent tSQLt-internal turmoil */
  EXEC ('CREATE SCHEMA MyInnerTests AUTHORIZATION [tSQLt.TestClass];');
  EXEC('
--[@'+'tSQLt:NoTransaction](DEFAULT)
CREATE PROCEDURE MyInnerTests.[test should cause unrecoverable error] AS PRINT CAST(''Some obscure string'' AS INT);
  ');

  EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.Private_CleanUp', @CommandToExecute = 'IF(@FullTestName <> ''[MyInnerTests].[test should cause unrecoverable error]'')BEGIN EXEC tSQLt.Private_NoTransactionHandleTables @Action=''Reset'';EXEC tSQLt.UndoTestDoubles @Force = 0;END;';
  EXEC tSQLt.SetSummaryError 0;

  EXEC tSQLt.Run 'MyInnerTests.[test should cause unrecoverable error]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT Name, Result, Msg INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected
  VALUES('[MyInnerTests].[test should cause unrecoverable error]', 'Error','Conversion failed when converting the varchar value ''Some obscure string'' to data type int.[16,1]{MyInnerTests.test should cause unrecoverable error,3}');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls user supplied clean up procedure after test completes]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserCleanUp1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserCleanUp1'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUp1]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));


  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'UserCleanUp1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test calls user supplied clean up procedure if it has a single quote in its name]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[UserClean''Up1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''UserClean''''Up1'');
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserClean''''Up1]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');

  CREATE TABLE #Actual (col1 NVARCHAR(MAX));


  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('UserClean''Up1');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test throws appropriate error if specified TestCleanUpProcedure does not exist]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUpDoesNotExist]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');

  
  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name,
         TR.Result,
         TR.Msg
    INTO #Actual
    FROM tSQLt.TestResult AS TR

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;

  INSERT INTO #Expected VALUES (
        '[MyInnerTests].[test1]',
        'Error', 
        'There is a problem with this annotation: [@tSQLt:NoTransaction](''[MyInnerTests].[UserCleanUpDoesNotExist]'')
Original Error: {16,10;(null)} Test CleanUp Procedure [MyInnerTests].[UserCleanUpDoesNotExist] does not exist or is not a procedure.')
  
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test throws appropriate error if specified TestCleanUpProcedure is not a procedure]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE VIEW [MyInnerTests].[NotAProcedure] AS SELECT 1 X;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''[MyInnerTests].[NotAProcedure]'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @Actual NVARCHAR(MAX) = (SELECT Msg FROM tSQLt.TestResult AS TR);
  EXEC tSQLt.AssertLike @ExpectedPattern = '%Test CleanUp Procedure [[]MyInnerTests].[[]NotAProcedure] does not exist or is not a procedure.', @Actual = @Actual;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test does not throw error if specified TestCleanUpProcedure is a CLR stored procedure]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    --[@'+'tSQLt:NoTransaction](''tSQLt_testutil.AClrSsp'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN
    END;
  ');
  EXEC tSQLt.SetSummaryError @SummaryError = 1;

  EXEC tSQLt.ExpectNoException;
  
  EXEC tSQLt.Run 'MyInnerTests.[test1]'--, @TestResultFormatter = 'tSQLt.NullTestResultFormatter';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test executes multiple TestCleanUpProcedure in the order they are specified]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp7] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp7''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp3] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp3''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp9] AS BEGIN INSERT INTO #Actual VALUES (''CleanUp9''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp7'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp3'')
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.CleanUp9'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'CleanUp7'),(3, 'CleanUp3'), (4, 'CleanUp9');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test executes schema CleanUp after test CleanUp]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[TestCleanUp] AS BEGIN INSERT INTO #Actual VALUES (''TestCleanUp''); END;');
  EXEC('CREATE PROCEDURE [MyInnerTests].[CleanUp] AS BEGIN INSERT INTO #Actual VALUES (''(Schema)CleanUp''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](''MyInnerTests.TestCleanUp'')
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      INSERT INTO #Actual VALUES (''test1'');
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run 'MyInnerTests.[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, 'test1'), (2, 'TestCleanUp'),(3, '(Schema)CleanUp');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test executes schema CleanUp only if it is a stored procedure]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE VIEW [MyInnerTests].[CleanUp] AS SELECT 1 X;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE MyInnerTests.[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.ExpectNoException;
  
  EXEC tSQLt.Run 'MyInnerTests.[test1]';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test executes schema CleanUp if schema name contains single quote]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInner''Tests'
  EXEC('CREATE PROCEDURE [MyInner''Tests].[CleanUp] AS BEGIN INSERT INTO #Actual VALUES (''[MyInner''''Tests].[CleanUp]''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInner''Tests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run '[MyInner''Tests].[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, '[MyInner''Tests].[CleanUp]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test executes schema CleanUp even if name is differently cased]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('CREATE PROCEDURE [MyInnerTests].[clEaNuP] AS BEGIN INSERT INTO #Actual VALUES (''[MyInnerTests].[clEaNuP]''); END;');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  CREATE TABLE #Actual (Id INT IDENTITY (1,1), col1 NVARCHAR(MAX));

  EXEC tSQLt.Run '[MyInnerTests].[test1]';

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES(1, '[MyInnerTests].[clEaNuP]');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test error in schema CleanUp procedure causes test result to be Error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  SELECT TR.Name, TR.Result INTO #Actual FROM tSQLt.TestResult AS TR;

  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  
  INSERT INTO #Expected VALUES('[MyInnerTests].[test1]','Error');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test writes an appropriate message to the tSQLt.TestResult table if schema CleanUp errors]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
    CREATE PROCEDURE [MyInnerTests].[CleanUp]
    AS
    BEGIN
      RAISERROR(''This is an error ;)'',16,10);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is an error ;) | Procedure: [MyInnerTests].[CleanUp] | Line: 4 | Severity, State: 16, 10)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO
CREATE PROCEDURE AnnotationNoTransactionTests.[test writes an appropriate message to the tSQLt.TestResult table if schema CleanUp has a different error]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyOtherInnerTests'
  EXEC('
    CREATE PROCEDURE [MyOtherInnerTests].[CleanUp]
    AS
    BEGIN
      /*wasting lines...*/
      RAISERROR(''This is another error ;)'',15,12);
    END;
  ');
  EXEC('
    --[@'+'tSQLt:NoTransaction](DEFAULT)
    CREATE PROCEDURE [MyOtherInnerTests].[test1]
    AS
    BEGIN
      RETURN;
    END;
  ');

  EXEC tSQLt.Run 'MyOtherInnerTests.[test1]', @TestResultFormatter = 'tSQLt.NullTestResultFormatter';

  DECLARE @FriendlyMsg NVARCHAR(MAX) = (SELECT TR.Msg FROM tSQLt.TestResult AS TR);
  
  EXEC tSQLt.AssertEqualsString @Expected = 'Error during clean up: (This is another error ;) | Procedure: MyOtherInnerTests.CleanUp | Line: 6 | Severity, State: 15, 12)', @Actual = @FriendlyMsg;
END;
GO
/*-----------------------------------------------------------------------------------------------*/
GO

/*-- TODO

 CLEANUP: named cleanup x 3 (needs to execute even if there's an error during test execution)
- there will be three clean up methods, executed in the following order
- X 1. User defined clean up for an individual test as specified in the NoTransaction annotation parameter
-- X "--[@tSQLt:NoTransaction]('[<SCHEMANAME>].[<SPNAME>]')"
-- X --[@tSQLt:NoTransaction](DEFAULT)

- 2. User defined clean up for a test class as specified by [<TESTCLASS>].CleanUp
-- X ' in schema name
-- X different case for cLEANuP
-- If the ERROR_PROCEDURE is somehow returning null, we still get the rest of the error message

- 3. tSQLt.Private_CleanUp
- Errors thrown in any of the CleanUp methods are captured and causes the test @Result to be set to Error
- If a previous CleanUp method errors or fails, it does not cause any following CleanUps to be skipped.
- appropriate error messages are appended to the test msg 
- If a test errors (even catastrophically), all indicated CleanUp procedures run.

- X handle multiple TestCleanUpProcedures
- X handle TestCleanUpProcedures with ' in name
- X error in annotation if specified TestCleanUpProcedure does not exist
- X error in annotation if specified TestCleanUpProcedure is not a procedure (any of the 4ish types)


Transactions
- transaction opened during test
- transaction commited during test
- inner-transaction-free test errors with uncommittable transaction
- confirm pre and post transaction counts match
- [test produces meaningful error when pre and post transactions counts don't match]
-  we still need to save the TranName as something somewhere.

SkipTest Annotation & NoTransaction Annotation
- The test is skipped
- No other objects are dropped or created
- No handler is called
- Transaction something something <-- this!

Everything is being called in the right order.
- test for execution in the correct place in Private_RunTest, after the outer-most test execution try catch
- Make sure undotestdoubles and handletables are called in the right order

- tSQLt.SpyProcedure needs a "call original" option
- What happens when we have multiple annotations for other non-NoTransaction annotations? Did we test this???
- Simulate Clippy if someone tries to use AssertEquals instead of AssertEqualsString

--*/