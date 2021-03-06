/****** Object:  Database [yappdb]    Script Date: 10.10.2020 14:36:35 ******/
CREATE DATABASE [yappdb]  (EDITION = 'Basic', SERVICE_OBJECTIVE = 'Basic', MAXSIZE = 2 GB) WITH CATALOG_COLLATION = SQL_Latin1_General_CP1_CI_AS;
GO
ALTER DATABASE [yappdb] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [yappdb] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [yappdb] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [yappdb] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [yappdb] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [yappdb] SET ARITHABORT OFF 
GO
ALTER DATABASE [yappdb] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [yappdb] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [yappdb] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [yappdb] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [yappdb] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [yappdb] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [yappdb] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [yappdb] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [yappdb] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [yappdb] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [yappdb] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [yappdb] SET  MULTI_USER 
GO
ALTER DATABASE [yappdb] SET ENCRYPTION ON
GO
ALTER DATABASE [yappdb] SET QUERY_STORE = ON
GO
ALTER DATABASE [yappdb] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 7), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 10, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/*** Сценарии конфигураций областей баз данных в Azure следует выполнять в подключении к целевой базе данных. ***/
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 8;
GO
/****** Object:  UserDefinedFunction [dbo].[datetime_to_int]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: Функция приведения даты в числовой формат. 
-- =============================================
CREATE FUNCTION [dbo].[datetime_to_int]
(
    -- Add the parameters for the function here
    @ds_val datetime
)
RETURNS int
AS
BEGIN
    -- Declare the return variable here
    DECLARE @int_val int

    -- Add the T-SQL statements to compute the return value here
	SELECT @int_val = YEAR(@ds_val) * 1000000 + MONTH(@ds_val) * 10000 + DAY(@ds_val)* 100 + DATEPART(hour,@ds_val) 
    -- Return the result of the function
    RETURN @int_val
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_ConvertToDateTime]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Функция конверирования даты в текстовом формате в значение форма datetime
*/

CREATE FUNCTION [dbo].[fn_ConvertToDateTime] (@Datetime BIGINT)
RETURNS DATETIME
AS
BEGIN
    DECLARE @LocalTimeOffset BIGINT
           ,@AdjustedLocalDatetime BIGINT;
    SET @LocalTimeOffset = DATEDIFF(second,GETDATE(),GETUTCDATE())
    SET @AdjustedLocalDatetime = @Datetime - @LocalTimeOffset
    RETURN (SELECT DATEADD(second,@AdjustedLocalDatetime, CAST('1970-01-01 00:00:00' AS datetime)))
END;
GO
/****** Object:  UserDefinedFunction [dbo].[timestamp_to_datetime]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: Функция конвертирования даты формата timestamp в формат datetime
-- =============================================
CREATE FUNCTION [dbo].[timestamp_to_datetime]
(
    -- Add the parameters for the function here
    @ts_val bigint
)
RETURNS datetime
AS
BEGIN
    -- Declare the return variable here
    DECLARE @ds_val datetime

    -- Add the T-SQL statements to compute the return value here
    SELECT @ds_val =  dateadd(MILLISECOND, @ts_val % 1000, dateadd(SECOND, @ts_val / 1000, cast('1970-01-01' as datetime2(7))))

    -- Return the result of the function
    RETURN @ds_val
END
GO
/****** Object:  UserDefinedFunction [dbo].[timestamp_to_int]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: Функция конвертирования даты формата timestamp в формат int 
-- =============================================
CREATE FUNCTION [dbo].[timestamp_to_int]
(
    -- Add the parameters for the function here
    @ts_val bigint
)
RETURNS int
AS
BEGIN
    -- Declare the return variable here
    DECLARE @int_val int, @ds_val datetime

    -- Add the T-SQL statements to compute the return value here
    SELECT @ds_val =  dateadd(MILLISECOND, @ts_val % 1000, dateadd(SECOND, @ts_val / 1000, cast('1970-01-01' as datetime2(7))))
	SELECT @int_val = YEAR(@ds_val) * 1000000 + MONTH(@ds_val) * 10000 + DAY(@ds_val)* 1000 + DATEPART(hour,@ds_val) 
    -- Return the result of the function
    RETURN @int_val
END
GO
/****** Object:  Table [dbo].[fact_incoming]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fact_incoming](
	[queueId] [varchar](50) NULL,
	[timestamp] [varchar](50) NULL,
	[new_t] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[fact_incoming_cl]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Очищенные и приведенные данные фактического количества обращений ******/

CREATE VIEW [dbo].[fact_incoming_cl] as (
	SELECT 
		sub.qid
		,sub.ts_int_agr
		,COUNT(*) as s_cnt
	FROM (
		SELECT 
			[queueId] as qid --номер линии
			,(SELECT dbo.datetime_to_int( dbo.[timestamp_to_datetime]([timestamp]))) as ts_int_agr -- дата типа int
			,(SELECT dbo.[timestamp_to_datetime]([timestamp])) as ts_datetime --дата типа datetime
			,[new_t] as new_t --id линии
		FROM [dbo].[fact_incoming] 
	 ) as sub
	 GROUP BY sub.ts_int_agr, sub.qid )
GO
/****** Object:  Table [dbo].[prediction_1]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[prediction_1](
	[start_of_hour] [varchar](50) NULL,
	[prediction] [varchar](50) NULL,
	[queueId] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[prediction_1_cl]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/****** Очищенные и приведенные данные прогноза 1 ******/

CREATE VIEW [dbo].[prediction_1_cl] as (
	SELECT 
		(SELECT dbo.datetime_to_int(start_of_hour)) as ts_int_agr --дата типа int
		,start_of_hour as ts_datetime --дата типа datetime
		,CAST(prediction as INT) as p_cnt --количество вызовов
		,queueId as qid --номер линии
	FROM dbo.prediction_1
	WHERE (SELECT  dbo.datetime_to_int(start_of_hour)) >= 2019122500
	)

	
GO
/****** Object:  Table [dbo].[prediction_2]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[prediction_2](
	[start_of_hour] [varchar](50) NULL,
	[prediction] [varchar](50) NULL,
	[queueId] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[prediction_2_cl]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/****** Очищенные и приведенные данные прогноза 2 ******/
CREATE VIEW [dbo].[prediction_2_cl] as (
--прогнозные данные 2
	SELECT 
		(SELECT dbo.datetime_to_int(start_of_hour)) as ts_int_agr --дата типа int
		,start_of_hour as ts_datetime --дата типа datetime
		,CAST(prediction as INT) as p_cnt --количество звонков
		,queueId as qid --номер линии
	FROM dbo.prediction_2
	WHERE (SELECT dbo.datetime_to_int(start_of_hour)) >= 2019122500)
	

	
GO
/****** Object:  View [dbo].[res_predictions_by_hours]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Агрегационные данные. Расчет ошибок обращений по часам
В запросе сначала считается кумулятивная сумма обращений по часам, чтобы убрать проблему проблему несоответсвия распределения обращений по времени между фактом и прогнозом
После приведения распределений по часам фактическому распределению, произодится возврат к абсолютным значением количества обращений через функцию LAG
******/
CREATE VIEW [dbo].[res_predictions_by_hours] as (
	SELECT --расчет абсолютых значений прогнозов и фактического количества обращений по часам
		sub_fct.ts_int_agr 
		,sub_fct.cumsum_fct_cnt - LAG(sub_fct.cumsum_fct_cnt, 1,0) OVER (ORDER BY sub_fct.ts_int_agr ) as fact_val --фактическое количество обращений по часам
		,sub_p1.cumsum_p1_cnt - LAG(sub_p1.cumsum_p1_cnt, 1,0) OVER (ORDER BY sub_fct.ts_int_agr ) as p1_val --количество обращений по часам прогноз 1
		,sub_p2.cumsum_p2_cnt - LAG(sub_p2.cumsum_p2_cnt, 1,0) OVER (ORDER BY sub_fct.ts_int_agr ) as p2_val --количество обращений по часам прогноз 2
	FROM (
		SELECT --кумулятивная сумма фактических обращений
			fct_agr.ts_int_agr
			,SUM(fct_agr.sum_cnt) OVER (ORDER BY fct_agr.ts_int_agr ASC) as cumsum_fct_cnt
			FROM (
				SELECT 
					fct.ts_int_agr
					,SUM(fct.s_cnt) as sum_cnt
				FROM fact_incoming_cl as fct
				GROUP BY fct.ts_int_agr ) as fct_agr
		) as sub_fct
	LEFT JOIN
		(SELECT --кумулятивная сумма прогноза 1 
			p1_agr.ts_int_agr
			,SUM(p1_agr.sum_cnt) OVER (ORDER BY p1_agr.ts_int_agr ASC) as cumsum_p1_cnt
			FROM (
				SELECT 
					p1.ts_int_agr
					,SUM(p1.p_cnt) as sum_cnt
				FROM prediction_1_cl as p1
				GROUP BY p1.ts_int_agr ) as p1_agr) as sub_p1
	ON sub_p1.ts_int_agr = sub_fct.ts_int_agr 
	LEFT JOIN
		(SELECT --кумулятивная сумма прогноза 2
			p2_agr.ts_int_agr
			,SUM(p2_agr.sum_cnt) OVER (ORDER BY p2_agr.ts_int_agr ASC) as cumsum_p2_cnt
			FROM (
				SELECT 
					p2.ts_int_agr
					,SUM(p2.p_cnt) as sum_cnt
				FROM prediction_2_cl as p2
				GROUP BY p2.ts_int_agr ) as p2_agr) as sub_p2
	ON sub_p2.ts_int_agr = sub_fct.ts_int_agr ) 
GO
/****** Object:  StoredProcedure [dbo].[measures_calculate]    Script Date: 10.10.2020 14:36:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: <Description, , >
-- =============================================
CREATE PROCEDURE [dbo].[measures_calculate]

AS
BEGIN
	CREATE TABLE #measure_values
		(m_title NVARCHAR(20),
		p1_value FLOAT,
		p2_value FLOAT,
		fact_value FLOAT)

INSERT INTO #measure_values 
VALUES ('test', 1.0,2.0,3.0)




    -- Insert statements for procedure here
    SELECT * FROM #measure_values
END
GO
ALTER DATABASE [yappdb] SET  READ_WRITE 
GO
