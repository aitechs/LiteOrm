/*
MODIFIED CODE FROM
__________________________________________________________________
Name:  CS SPROC Builder
Version: 1
Date:  10/09/2004
Author:  Paul McKenzie
*/

SET NOCOUNT ON;
DECLARE @objName NVARCHAR(100);
DECLARE @parameterCount INT;
DECLARE @errMsg VARCHAR(100);
DECLARE @parameterAt VARCHAR(1);
DECLARE @connName VARCHAR(100);

DECLARE @params	    nvarchar(max);
DECLARE @paramsDeclare  nvarchar(max);
DECLARE @fields	    nvarchar(max);
DECLARE @fieldsAt	    nvarchar(max);


DECLARE @interface	nvarchar(max) = '';
DECLARE @Original	nvarchar(max) = '';
DECLARE @Equal		nvarchar(max) ='';
DECLARE @Equal2	nvarchar(max) = '';
DECLARE @Equal3	nvarchar(max) = '';
DECLARE @ClassName	nvarchar(100);

--//Change the following variable to the name of your connection instance
SET @params		= '';
SET @paramsDeclare	= '';
SET @fields		= '';
SET @fieldsAt		= '';


SET @connName = 'db';
SET @parameterAt = '';
SET @objName = 'MTOP_Transactions';

SET @ClassName= 'Transaction';


SELECT dbo.sysobjects.name AS ObjName,
       dbo.sysobjects.xtype AS ObjType,
       dbo.syscolumns.name AS ColName,
       dbo.syscolumns.colorder AS ColOrder,
       dbo.syscolumns.length AS ColLen,
       dbo.syscolumns.colstat AS ColKey,
       dbo.systypes.xtype
INTO #t_obj

FROM dbo.syscolumns
     INNER JOIN dbo.sysobjects ON dbo.syscolumns.id = dbo.sysobjects.id
     INNER JOIN dbo.systypes ON dbo.syscolumns.xtype = dbo.systypes.xtype
WHERE(dbo.sysobjects.name = @objName)
     AND (dbo.systypes.status <> 1)
--*ORDER BY 
    --dbo.sysobjects.name, 
    --dbo.syscolumns.colorder;

SET @parameterCount = ( SELECT COUNT(*) FROM #t_obj );


IF(@parameterCount < 1)
    SET @errMsg = 'No Parameters/Fields found for '+@objName;

IF(@errMsg IS NULL)
    BEGIN
        DECLARE @source_name NVARCHAR, @source_type VARCHAR, @col_name NVARCHAR(100), @col_order INT, @col_type VARCHAR(20), @col_len INT, @col_key INT, @col_xtype INT, @col_redef VARCHAR(20);
        DECLARE cur CURSOR
        FOR
            SELECT *
            FROM #t_obj order by ColOrder;
        OPEN cur;
       
       -- Perform the first fetch.
        FETCH NEXT FROM cur INTO @source_name, @source_type, @col_name, @col_order, @col_len, @col_key, @col_xtype;
        IF(@source_type = N'U')
            SET @parameterAt = '@';
  
       -- Check @@FETCH_STATUS to see if there are any more rows to fetch.
        WHILE @@FETCH_STATUS = 0
            BEGIN
             --print @col_xtype;

                SET @col_redef =
                (
                    SELECT CASE @col_xtype
                               WHEN 34 THEN 'Image'
                               WHEN 35 THEN 'string'	-- 'Text'
                               WHEN 40 THEN 'DateTime'	-- 'Date'
                         WHEN 48 THEN 'int'		-- 'TinyInt'
                               WHEN 52 THEN 'int'		-- 'SmallInt'
                               WHEN 56 THEN 'int'		--'Int'
                               WHEN 58 THEN 'DateTime'	--'SmallDateTime'
                               WHEN 59 THEN 'Double'	--'Real'
                               WHEN 60 THEN 'Decimal'	--'Money'
                               WHEN 61 THEN 'DateTime'	-- 'DateTime'
                               WHEN 62 THEN 'Double'	--'Float'
                               WHEN 99 THEN 'string'	--'NText'
                               WHEN 104 THEN 'bool'		--'Bit'
                               WHEN 106 THEN 'Decimal'	--'Decimal'
                               WHEN 122 THEN 'Decimal'	--'SmallMoney'
                               WHEN 127 THEN 'long'		--'BigInt'
                               WHEN 165 THEN 'VarBinary'
                               WHEN 167 THEN 'string'	--'VarChar'
                               WHEN 173 THEN 'Binary'
                               WHEN 175 THEN 'string'	--'Char'
                               WHEN 231 THEN 'string'	--'NVarChar'
                               WHEN 239 THEN 'string'	--'NChar'
                               ELSE '!MISSING'
                           END AS C
                ); 
   
          if (@col_name <> 'Created' and 
             @col_name <> 'Modified' and
             @col_name <> 'CreatedBy' and
             @col_name <> 'ModifiedBy' and
             @col_name <> 'Id') begin

          --If the type is a string then output the size declaration
                IF(@col_xtype = 231)
                  OR (@col_xtype = 167)
                  OR (@col_xtype = 175)
                  OR (@col_xtype = 99)
                  OR (@col_xtype = 35)
                begin
                    SET @paramsDeclare = CONCAT(@paramsDeclare, space(12) + 'new SqlParameter( "'+ @parameterAt + @col_name + '", SqlDbType.'+ @col_redef + ', ' + CAST(@col_len AS VARCHAR) + ') ,' + char(13))
                end
             ELSE
                --Write out the parameter
                SET @paramsDeclare = CONCAT(@paramsDeclare, space(12) + 'new SqlParameter( "'+ @parameterAt + @col_name + '", SqlDbType.'+ @col_redef + ') ,' + char(13))

            -- This is executed as long as the previous fetch succeeds.
             SET @interface = CONCAT(@interface,space(8), @col_redef +' ' + @col_name +' { get; set;}', char(13))
             SET @fields = CONCAT(@fields,space(8), 'public ' + @col_redef +' ' + @col_name +' { get; set;}', char(13))
             
             SET @Original = CONCAT(@Original, space(12), 'OriginalValues.Add("'+ @col_name+'", this.'+ @col_name+');', CHAR(13));

             if len(@equal) < 3000
                SET @Equal = CONCAT (@Equal, space(12), 'if (!Equals(this.'+ @col_name +', OriginalValues["'+ @col_name +'"])) changes.Add("'+ @col_name +'", this.'+ @col_name +');', char(13))
             else
                IF LEN(@Equal2) < 3000
                    SET @Equal2 = CONCAT (@Equal2, space(12), 'if (!Equals(this.'+ @col_name +', OriginalValues["'+ @col_name +'"])) changes.Add("'+ @col_name +'", this.'+ @col_name +');', char(13))
                else
                    SET @Equal3 = CONCAT (@Equal3, space(12), 'if (!Equals(this.'+ @col_name +', OriginalValues["'+ @col_name +'"])) changes.Add("'+ @col_name +'", this.'+ @col_name +');', char(13))
          END 
                FETCH NEXT FROM cur INTO @source_name, @source_type, @col_name, @col_order, @col_len, @col_key, @col_xtype;	 	   
       END;
       

       PRINT 'using System;
using System.Collections.Generic;
using Dapper.Contrib.Extensions;
using AiTech.CrudPattern;

namespace Dll.MTOP
{
    public interface I' + @ClassName
    print '    {'           		
PRINT @interface        
print '    }



    [Table("'+@objName+'")]
    public class '+@className+': Entity, I'+@ClassName+'
    {		
        Dictionary<string,object> OriginalValues;

        #region Default Properties'

    PRINT @fields        
    PRINT '		#endregion
        

        public void InitializeTrackingChanges()
        {
            OriginalValues = new Dictionary<string,object>();'

        print @Original
            --OriginalValues.Add("Code", this.Code);        
    PRINT'		}

        override public Dictionary<string,object> GetChanges()
        {
            var changes = new Dictionary<string, object>();'

            PRINT @Equal 
            print @Equal2 
            print @Equal3
                                
            --if(!Equals(this.Code, OriginalValues["Code"]))
            --	changes.Add("Code", this.Code);
    PRINT '			return changes;
        }

        
    }
    
}'
       



        CLOSE cur;
        DEALLOCATE cur;
END;

IF(LEN(@errMsg) > 0)
    PRINT @errMsg;

DROP TABLE #t_obj;
SET NOCOUNT ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO
SET ANSI_NULLS ON;
GO