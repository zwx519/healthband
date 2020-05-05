--必须在这个位置定义PROJECT和VERSION变量
PROJECT = "GPS"
VERSION = "1.0.0"
--BUG修复记录

--基站定位用
PRODUCT_KEY = "enfFQUSPW1IrCToRGhpkaI3fbZ3UKioz"

require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE
--LOG_LEVEL = log.LOGLEVEL_ERROR
--LOG_LEVEL = log.LOGLEVEL_FATAL

require "sys"
require "sim"
require "misc"
require "net"
require "pm"
require "lbsLoc"
require "netLed"
require"Config"
require "nvm"
require "ntp"

ntp.timeSync() -- 只同步1次时间

net.startQueryAll(30000, 30000)

netLed.setup(true,pio.P0_28)

pmd.ldoset(5, pmd.LDO_VIB) --打开LDO，2.8V

nvm.init("Config.lua")  --初始化文件系统

require "MAX30100"
require "GetLocation"
require "AliIOT"
require "MPU6050"

--启动系统框架
sys.init(0, 0)
sys.run()



