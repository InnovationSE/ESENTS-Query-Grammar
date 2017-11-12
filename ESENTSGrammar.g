grammar QueryGrammar;

options {
  language = C;
  output = AST;
  //ASTLabelType=CommonTree;
  ASTLabelType	= pANTLR3_BASE_TREE;
  k=3;
}


tokens {
COMMAND;
TYPE;
TAG;
TAGS;
EXPRESSIONS;
OPERATION;
VALUE_EQUATION;
STATUS_EQUATION;
UNIT_EQUATION;
NAME_EQUATION;
BLOCK_EQUATION;
BLOCK_TAGS;
BLOCK_TEMPORAL;
UTC;
DATE;
TIME;
EVERY;
TOWARDS;
HOST;
VALUE_TS_EQUATION_BLOCK;
DURATION_TS_EQUATION_BLOCK;
TIME_TS_EQUATION_BLOCK;
TIME_EQUATION;
DURATION_EQUATION;
TIME_RANGE_TS_BLOCK;
TIME_QUERY;
DURING_TIME;
GROUPBY_BLOCK;
} 

@header {
#include "antlr3_Exception.h"
}

@members {
//displayRecognitionError
/*static void displayRecognitionErrorNew (pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
    printf("Error detected, this my own error function");
}*/

}

@parser::apifuncs {
  RECOGNIZER->displayRecognitionError       = SRE_setAntlr3ExceptionDetails;
 // RECOGNIZER->antlr3RecognitionExceptionNew = antlr3RecognitionExceptionNewNew;
 // RECOGNIZER->mismatch                      = mismatchNew;
}
// Code to be executed when an erroneous token is found in the input data.
// otherwise, the error will be notified and the token ignored. 
@rulecatch{  
  // This code is executed afted each token detection, 
  // must verify if an exception is occured before reporting error.
	if (HASEXCEPTION())
    {
      // This is the function that will call RECOGNIZER->displayRecognitionError
      // which is overridden by our function setExceptionDetails
      PREPORTERROR();
    }
}

  
/** ----------------------------------------------- 
              --- PARSER RULES ---
--------------------------------------------------*/

/*
	words "MAX", "MIN", "STATUS" generates some warnings when compiling 
	because these words are already defined in some libraries
	an underscore '_' is added at the end of each of these words.
*/


/*--- full query definition --- */
query
  :
  command type (block_tags (equation_expression)?) EOF
  | operation variable (block_tags (equation_expression)?) EOF  
  | remoteCmd type (block_tags (equation_expression)?) temporal? sampling? towards? EOF
  | timeSeries_query EOF
  ;
 
timeSeries_query
  :
   timeSeries_value_query 
   | timeSeries_time_query  
  ;
timeSeries_value_query
  :
   command values block_tags (ts_filter_equation_expression)? (ts_value_equation_expression)? (ts_time_equation_expression)? ts_time_range_expression? 
   |operation values block_tags (ts_filter_equation_expression)? (ts_value_equation_expression)? (ts_time_equation_expression)? ts_time_range_expression? groupBy? 
  ;


timeSeries_time_query
  :
    timeSeries_time_query_expression //(UNION^ timeSeries_time_query_expression)* 
  ;

timeSeries_time_query_expression
  :
  command times block_tags ts_filter_equation_expression? (ts_value_equation_expression (ts_duration_equation_expression)?)? ts_time_equation_expression? ts_time_range_expression?
  | LEFT_PARENTHESES! timeSeries_time_query  RIGHT_PARENTHESES!
  ;
/*
timeSeries_time_query
  :
  timeSeries_time_query_expression (UNION^ timeSeries_time_query_expression)* 
  | timeSeries_time_query_exp
 // | LEFT_PARENTHESES! timeSeries_time_query_expression  RIGHT_PARENTHESES!
    
//    timeSeries_time_query_expression (UNION^ timeSeries_time_query_expression)* 
  ;

timeSeries_time_query_expression
  :
    timeSeries_time_query_expr -> ^(TIME_TS_EQUATION_BLOCK timeSeries_time_query_expr)
    | LEFT_PARENTHESES! timeSeries_time_query  RIGHT_PARENTHESES!
  ;

timeSeries_time_query_expr
  :
    timeSeries_time_query_exp
  ;

timeSeries_time_query_exp
  :
   command times block_tags ts_filter_equation_expression? (ts_value_equation_expression (ts_duration_equation_expression)?)? ts_time_equation_expression? ts_time_range_expression?
   
  ;

  
/* --- Commands --- */
command
  :
  SEARCH -> ^(COMMAND SEARCH)
  | UPDATE -> ^(COMMAND UPDATE)
  | INVOKE -> ^(COMMAND INVOKE)
  | ADDTAG -> ^(COMMAND ADDTAG)
  | DELETETAG -> ^(COMMAND DELETETAG)
  | UPDATETAG -> ^(COMMAND UPDATETAG)
  ;

remoteCmd:
   SUBSCRIBE  -> ^(COMMAND SUBSCRIBE)
  | COLLECT -> ^(COMMAND COLLECT)
;

/* --- operation --- */
operation
  :
  SUM -> ^(COMMAND SUM)
  | AVG -> ^(COMMAND AVG)
  | MIN_ -> ^(COMMAND MIN_)
  | MAX_ -> ^(COMMAND MAX_)
  | COUNT -> ^(COMMAND COUNT)
;


/* --- operator --- */
operator
  :
  OR -> ^(OR) 
  | AND -> ^(AND)
  ;
 


/* --- type --- */

type
  :
  VARIABLE  -> ^(TYPE VARIABLE)
  | SERVICE -> ^(TYPE SERVICE)
  | DEVICE -> ^(TYPE DEVICE)
  | SERVICEBUS -> ^(TYPE SERVICEBUS)
  | ANY -> ^(TYPE ANY)
  ;

variable
  :
  VARIABLE  -> ^(TYPE VARIABLE)
  ;

/* --- expressions --- */
equation_expression
  :
  equation_block -> ^(BLOCK_EQUATION equation_block)
  ;

equation_block :
  WITH! equation_expr
  ;
  
equation_expr
  :
  or_equation 
  ;
  
or_equation
  :
  //The order of precedence is for the AND
  and_equation (OR^ and_equation)*
  ;
  
and_equation
 :
  equation (AND^ equation)* 
  ;
  
equation
  :
    value_equation -> ^(VALUE_EQUATION value_equation)
    | status_equation -> ^(STATUS_EQUATION status_equation)
    | unit_equation -> ^(UNIT_EQUATION unit_equation)
    | name_equation -> ^(NAME_EQUATION name_equation)
    | LEFT_PARENTHESES! equation_expr RIGHT_PARENTHESES!
  ;

/* --- with value --- */
//the ! character is used to filter the With String, it will not be passed to the tree
value_equation
  :
   VALUE evaluators (STRING|INTEGER)
  ;

status_equation
  :
  STATUS_ Q_DOUBLE_EQ STRING
  | STATUS_ Q_DIFFERENT STRING
  ;
  
unit_equation
  :
  UNIT Q_DOUBLE_EQ STRING
  |  UNIT Q_DIFFERENT STRING
  ;


name_equation
  :
  NAME Q_DOUBLE_EQ STRING
  | NAME Q_DIFFERENT STRING
  ;


/*****************************************************************************************************************************
                                          Time Series Query                                                              
/*****************************************************************************************************************************/

/*-------------- Time Series query types ---------------*/
values
  :
  VALUES  -> ^(TYPE VALUES)
  ;

times
  :
  TIMES  -> ^(TYPE TIMES)
  ;


/*-------------- Time Series Filter Equation ---------------*/

ts_filter_equation_expression
  :
  ts_filter_equation_block -> ^(BLOCK_EQUATION ts_filter_equation_block)
  ;
  
ts_filter_equation_block 
  :
  WITH! ts_or_filter_equation
  ;
  
ts_or_filter_equation
  :
  ts_and_filter_equation (OR^ ts_and_filter_equation)*
  ;
  
ts_and_filter_equation
 :
  ts_filter_equation (AND^ ts_filter_equation)* 
  ;
  
ts_filter_equation
  :
      unit_equation -> ^(UNIT_EQUATION unit_equation)
    | name_equation -> ^(NAME_EQUATION name_equation)
    | LEFT_PARENTHESES! ts_or_filter_equation RIGHT_PARENTHESES!
  ;



/*-------------- Time Series Value Equation --------------*/
ts_value_equation_expression
  :
  ts_value_equation_block -> ^(VALUE_TS_EQUATION_BLOCK ts_value_equation_block)
  ;
  
ts_value_equation_block 
  :
  WHERE! ts_or_value_equation
  ;

ts_or_value_equation
  :
  //The order of precedence is for the AND
  ts_and_value_equation (OR^ ts_and_value_equation)*
  ;
  
ts_and_value_equation
 :
  ts_value_equation (AND^ ts_value_equation)* 
  ;

ts_value_equation 
  :
    ts_value_one_equation -> ^(VALUE_EQUATION  ts_value_one_equation)
  | LEFT_PARENTHESES! ts_or_value_equation RIGHT_PARENTHESES!
  ;

ts_value_one_equation
  :
     VALUE evaluators INTEGER  
  ;





/*-------------- Time series Time Equation --------------*/
ts_time_equation_expression
  :
  ts_time_equation_block -> ^(TIME_TS_EQUATION_BLOCK ts_time_equation_block)
  ;
  
ts_time_equation_block 
  :
  WHEN! ts_or_time_equation
  ;
  
ts_or_time_equation
  :
  //The order of precedence is for the AND
  ts_and_time_equation (OR^ ts_and_time_equation)*
  ;
  
ts_and_time_equation
 :
  ts_time_equation (AND^ ts_time_equation)* 
  ;

ts_time_equation
  :
    ts_time_one_equation -> ^(TIME_EQUATION ts_time_one_equation)
  | LEFT_PARENTHESES! ts_or_time_equation RIGHT_PARENTHESES!
  ;
 
ts_time_one_equation
  :
    YEAR evaluators INTEGER
  | MONTH evaluators INTEGER
  | DAY evaluators INTEGER
  | WDAY evaluators INTEGER
  | HOURS evaluators INTEGER
  | MINUTES evaluators INTEGER
  | SECONDS evaluators INTEGER  
  ;

/*-------------- Time Series Duration Equation --------------*/
ts_duration_equation_expression
  :
  ts_duration_equation_block -> ^(DURATION_TS_EQUATION_BLOCK ts_duration_equation_block)
  ;
  
ts_duration_equation_block 
  :
  DURING! ts_or_duration_equation
  ;
  
ts_or_duration_equation
  :
  //The order of precedence is for the AND
  ts_and_duration_equation (OR^ ts_and_duration_equation)*
  ;
  
ts_and_duration_equation
 :
  ts_duration_equation (AND^ ts_duration_equation)* 
  ;
  
ts_duration_equation
  :
    ts_duration_one_equation -> ^(DURATION_EQUATION ts_duration_one_equation)
  | LEFT_PARENTHESES! ts_or_duration_equation RIGHT_PARENTHESES!
  ;
ts_duration_one_equation
  :
     TIME_TS evaluators timeUTC ->  TIME_TS evaluators  ^(TIME timeUTC)
  ;

/*-------------- Time Series Time Range Expression --------------*/

ts_time_range_expression
  :
  ts_time_range_block -> ^(TIME_RANGE_TS_BLOCK ts_time_range_block)
  ;
  
ts_time_range_block 
  :
      temporal 
    | WITHIN! LEFT_PARENTHESES! ts_nested_time_query  RIGHT_PARENTHESES! //->  ^(TIME_QUERY ts_nested_time_query)

  ;
 
ts_nested_time_query
  :
   ts_nested_time_query_union
  ;
  


ts_nested_time_query_union
  :
  ts_nested_time_query_expression (UNION^ ts_nested_time_query_expression)*
  ;
  
ts_nested_time_query_expression
  :
    timeSeries_time_query -> ^(TIME_QUERY timeSeries_time_query)
  ;

/*
timeSeries_time_query
  :
  timeSeries_time_query_expression (UNION^ timeSeries_time_query_expression)* 
  | timeSeries_time_query_exp
 // | LEFT_PARENTHESES! timeSeries_time_query_expression  RIGHT_PARENTHESES!
    
//    timeSeries_time_query_expression (UNION^ timeSeries_time_query_expression)* 
  ;

timeSeries_time_query_expression
  :
    timeSeries_time_query_expr -> ^(TIME_TS_EQUATION_BLOCK timeSeries_time_query_expr)
    | LEFT_PARENTHESES! timeSeries_time_query  RIGHT_PARENTHESES!
  ;

timeSeries_time_query_expr
  :
    timeSeries_time_query_exp
  ;

timeSeries_time_query_exp
  :
   command times block_tags ts_filter_equation_expression? (ts_value_equation_expression (ts_duration_equation_expression)?)? ts_time_equation_expression? ts_time_range_expression?
   
  ;

  
/* --- Commands --- */
/*-------------- Time Series Group By Expression --------------*/

groupBy
  :
    groupBy_statement -> ^(GROUPBY_BLOCK groupBy_statement)
   ;
groupBy_statement
  :
    GROUP_BY groupBy_items
  ;

GROUP_BY 
  :
  'GROUP BY' | 'Group By' | 'group by'
  ;
  
WHEN
  :
  'WHEN'  | 'When' | 'when'
  ;
WHERE
  :
  'WHERE'  | 'Where' | 'where'
  ;
  
WITHIN
  :
  'WITHIN'  | 'Within' | 'within'
  ;

groupBy_items
  :
    VARIABLE
    | DEVICE
    | YEAR
    | MONTH
    | WDAY
    | DAY
    | HOURS
    | MINUTES
    | TIMES
    ;
    

/* --- evaluators --- */
evaluators
  :
  Q_LOWER
  | Q_LOWER_EQUAL
  | Q_EQUAL
  | Q_DOUBLE_EQ
  | Q_GREATER_EQUAL
  | Q_GREATER
  | Q_DIFFERENT
  ;







/* --- Tags --- */ 
block_tags
  :
  or_tags -> ^(BLOCK_TAGS or_tags)
  ;
  
or_tags
  :
  //The order of precedence is for the AND
  and_tags (OR^ and_tags)*
  ;
  
and_tags
 :
  tag (AND^ tag)* 
  ;
  
tag
  :
   INFERENCE? STRING NS_SEPARATOR STRING -> ^(TAG INFERENCE? STRING STRING)
    | LEFT_PARENTHESES! block_tags RIGHT_PARENTHESES!
  ;

/* --- Temporal --- */ 
temporal
  :
    from_date to_date -> ^(BLOCK_TEMPORAL from_date to_date)
  ;

from_date:
  FROM date -> ^(FROM date)
;

to_date:
  TO date -> ^(TO date)
;

date
:
  dateUTC (TIME_SP timeUTC)? -> ^(DATE dateUTC) ^(TIME timeUTC)?
;

//1997-07-16T19:20:30
dateUTC :
INTEGER ('-'! INTEGER ('-'! INTEGER)?)? 
  ;
  
timeUTC: 
 INTEGER (':'! INTEGER (':'! INTEGER)?)? 
;
/** ----------------------------------------------- 
              --- LEXER TOKENS ---
--------------------------------------------------*/
/* --- namespaces --- */
NS_SEPARATOR
  :  
  ':'  
  ; 
  
sampling:
  EVERY timeUTC -> ^(EVERY timeUTC)
;  
 
towards:
  TOWARDS destination -> ^(TOWARDS destination)
  ;
  
  
 destination:
 STRING | URL
 ; 
 
 
SEARCH        : 'Search' | 'search'; 
UPDATE        : 'Update' | 'update';
INVOKE        : 'Invoke' | 'invoke';
SUBSCRIBE     : 'Subscribe' | 'subscribe';
ADDTAG        : 'AddTag' | 'addtag' | 'Addtag';
UPDATETAG     : 'UpdateTag' | 'updatetag' | 'Updatetag';
DELETETAG     : 'DeleteTag' | 'deletetag' | 'Deletetag';
COLLECT       : 'COLLECT' | 'Collect' | 'collect';
SUM           : 'SUM'  | 'Sum' | 'sum';
AVG           :  'AVG' | 'Avg' | 'avg';
MIN_           :  'MIN' | 'Min' | 'min';
MAX_           :  'MAX' | 'Max' | 'max';
EVERY         :  'Every' | 'EVERY' | 'every';


/* --- INFERENCE --- */
INFERENCE :
  '@'
  ;

/* --- OPERATORS --- */
OR
  :
  'or'
  ;

AND
  :
  'and'
  ;

/* --- TARGETS --- */
VARIABLE
  :
  'Variable' | 'variable'
  ;

SERVICE
  :
  'Service' | 'service'
  ;

DEVICE
  :
  'Device' | 'device'
  ;

SERVICEBUS
  :
  'Servicebus' | 'servicebus'
  ;

ANY
  :
  'Any'  | 'any'
  ;


/* --- restriction --- */
WITH
  :
  'with'
  ;

VALUE
  :
  'Value' | 'value'
  ;

STATUS_
  :
  'Status'  | 'status'
  ;

UNIT
  :
  'Unit'  | 'unit'
  ;
  
NAME
  :
  'Name'  | 'name'
  ;

ID
  :
  'ID' | 'Id' | 'id'
  ;


VALUES
  :
  'VALUES' | 'values' | 'Values'
  ;
DURING
  :
  'DURING' | 'During' | 'during'
  ;
TIME_TS
  :
  'TIME' | 'time' | 'Time'
  ;
YEAR
  :
  'YEAR' | 'Year' | 'year'
  ;
MONTH
  :
  'MONTH' | 'Month' | 'month'
  ;
DAY
  :
  'DAY' | 'Day' | 'day'
  ;
WDAY
  :
  'WDAY' | 'wday' | 'WDay' | 'Wday'
  ;
HOURS
  :
  'HOURS' | 'Hours' | 'hours'
  ;
MINUTES
  :
  'MINUTES' | 'Minutes' | 'minutes'
  ;
SECONDS  
  :
  'SECONDS' | 'Seconds' | 'seconds'
  ;

COUNT 
  : 
  'COUNT' | 'Count' | 'count'
  ;
TIMES 
  :
  'TIMES' | 'Times' | 'times'
  ;
  
UNION
  :
  'UNION' | 'Union'  | 'union'
  ;

/* --- evaluators --- */
Q_LOWER
  :
  '<'
  ;

Q_LOWER_EQUAL
  :
  '<='
  ;

Q_EQUAL
  :
  '='
  ;

Q_DOUBLE_EQ
  :
  '=='
  ;
  

Q_GREATER_EQUAL
  :
  '>='
  ;

Q_GREATER
  :
  '>'
  ;

Q_DIFFERENT
  :
  '!='
  ;

LEFT_PARENTHESES
  :
  '('
  ;

RIGHT_PARENTHESES
  :
  ')'
  ;

TIME_SP:
  'T'
  ;

/*--- generic definition --- */
WS
  :
  (
    ' '
    | '\t'
    | '\n'
    | '\r'
  )+ { $channel=HIDDEN; } 
  ;


COMMENT
  :
  '//'
  ~(
    '\n'
    | '\r'
   )*
  '\r'? '\n' 
            {
             $channel=HIDDEN;
            }
  | '/*' (options {greedy=false;}: .)* '*/' 
                                           {
                                            $channel=HIDDEN;
                                           }
  ;

fragment DIGIT: '0'..'9';

INTEGER : DIGIT+;
             
URL:
 ('http://' (STRING (('-'| '.')* ))+ (NS_SEPARATOR INTEGER)? '/' ( STRING ('-'| '.' | '?' | '#' | '/'| Q_EQUAL)* )* ) 
 ;

FROM
  :
  'from' | 'FROM' | 'From'
  ;
  
TO
  :
  'To' | 'TO' | 'to'
  ;
  
TOWARDS :
  'TOWARDS' | 'towards' | 'Towards'
  ;

STRING
  :
  ('a'..'z' | 'A'..'Z' | '0'..'9' | '_')+
  | ('"' ((~'"') | '""')* '"')
  ;
  
