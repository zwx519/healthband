--使能MPU6050震动检测中断
module(..., package.seeall)

require "sys"
require "misc"
require "pins"

--初始化，配置MPU6050
function Init_MPU6050()
    local i2cslaveaddr = 0x68 --mpu6050
    local i2cid = 2
    if i2c.setup(i2cid, i2c.SLOW) ~= i2c.SLOW then
        log.error("Init_MPU6050.iic", "fail")
        return
    end
    i2c.send(i2cid, i2cslaveaddr, {0X6b, 0x80})--复位
    rtos.sleep(100)
    i2c.send(i2cid, i2cslaveaddr, {0X6b, 0x00})--唤醒
    rtos.sleep(100)
    i2c.send(i2cid, i2cslaveaddr, {0x19, 19})--采样率50hz
    i2c.send(i2cid, i2cslaveaddr, {0x1b, 0x80})--陀螺仪传感器±250度/s
    i2c.send(i2cid, i2cslaveaddr, {0x1c, 0x00})--加速度传感器±2g
    i2c.send(i2cid, i2cslaveaddr, {0x1F, 0x0A})--运动检测设置 32mg/LSB
    i2c.send(i2cid, i2cslaveaddr, {0x20, 0x05})--运动检测时间设置 1ms/LSB
    i2c.send(i2cid, i2cslaveaddr, {0x23, 0x00})--关闭fifo
    i2c.send(i2cid, i2cslaveaddr, {0x37, 0x80})--int引脚低电平有效
    i2c.send(i2cid, i2cslaveaddr, {0x38, 0x40})--打开运动检测中断   通过读取0X3A来判断是否有中断现象
    i2c.send(i2cid, i2cslaveaddr, {0x6a, 0x00})--I2C主模式关闭
    i2c.close(i2cid)
end
--读取中断状态寄存器，并判断是否是震动中断
function Read_MPU6050_Interrupt()
    local i2cslaveaddr = 0x68 --mpu6050
    local i2cid = 2
    if i2c.setup(i2cid, i2c.SLOW) ~= i2c.SLOW then
        log.error("Read_MPU6050_Interrupt.iic", "fail")
        return
    end
    i2c.send(i2cid, i2cslaveaddr, 0x3a)--读取中断寄存器
    local Interupt = i2c.recv(i2cid, i2cslaveaddr, 1)
    Interupt = Interupt:byte()
    --log.info("Read_MPU6050_Interrupt.1",Interupt)
    i2c.close(i2cid)
    if bit.isset(Interupt, 6) then
        --如果确认是震动中断，则向系统中发射信号
        log.error("Read_MPU6050_Interrupt.1", Interupt)
        sys.publish("SOS")--发布SOS到系统中
    
    end
end

Init_MPU6050()--初始化MPU6050
sys.timerLoopStart(Read_MPU6050_Interrupt, 500)
