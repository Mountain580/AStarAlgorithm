package com.youzu.tot.myTest {
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.utils.clearInterval;
    import flash.utils.getTimer;
    import flash.utils.setInterval;

    /**
     * Author: Moutain
     * Date: 2016/10/20
     */

    public class AStarAlgorithm extends Sprite{
        public static const WIDTH_TOTAL:int = 512;//总宽度;
        public static const HEIGHT_TOTAL:int =512;//总高度;
        public static const GRID_WIDTH:int = 8;//方格宽度;
        public static const GRID_HEIGHT:int =8;//方格高度;
        public static const GRID_HTOTAL:int = WIDTH_TOTAL / GRID_WIDTH;//水平方格总数;
        public static const GRID_VTOTAL:int = HEIGHT_TOTAL / GRID_HEIGHT;//垂直方格总数;
        public static const NC_COUNT:int = 512;//障碍物总数;
        public static const NC_HTOTAL:int = 32;//水平障碍总数;
        public static const NC_VTOTAL:int = 32;//垂直障碍总数;
        private var scene:Sprite;//场景
        private var player:Sprite;//控制点
        private var path:Array;//行走路径
        private var Node:Object;//父节点
        private var drawpath:Sprite; //路径绘制
        private var openList:Array;//开放列表;
        private var closeList:Object;//关闭列表;
        private var coordinate:Array;//全局坐标;
        private var tx:int;//目标x坐标点;
        private var ty:int;//目标y坐标点;
        private var nx:int;//当前x坐标点;
        private var ny:int;//当前Y坐标点;
        private var InID:int = 0;//intervalID
        private var flag:Boolean;  //一个开关

        public function AStarAlgorithm() {
            init();
        }

        //===========================================================================================初始化;
        private function init() {
            create_scene();//场景;
            create_coordinate();//全局坐标;
            create_nc();//障碍物;
            create_player();//控制点;
            create_UI();//显示信息;
            scene.addEventListener(MouseEvent.CLICK,clk);//侦听鼠标点击
            drawpath=new Sprite();//路径绘制
            addChild(drawpath);
        }

        //创建显示信息;
        private function create_UI() {
            var bt:Sprite=new Sprite();//按钮
            //引用场景宽度;
            var sw:int=scene.width+2;
            bt.x = sw;
            bt.y = 450;
            bt.graphics.beginFill(0xdddddd,1);
            bt.graphics.drawRoundRect(0,0,60,20,10,10);
            bt.graphics.endFill();
            var lab:TextField=new TextField();//按钮标签
            lab.text = "重置";
            lab.selectable = false;
            lab.x=15;
            lab.width = 30;
            lab.height = 20;
            bt.addChild(lab);
            addChild(bt);
            bt.addEventListener(MouseEvent.CLICK,btclk);
            createText(sw,100,"场景信息\n_____________");
            createText(sw,140,"方格总数:"+GRID_HTOTAL+"*"+GRID_VTOTAL);
            createText(sw,160,"障碍总数:"+NC_COUNT+"\n_____________");
            createText(sw,200,"","msg");
            createText(sw,10,"制作：浩天\nQQ：1099157685")
        }

        //创建显示文本
        private function createText(x:int,y:int,txt:String,name:String=""):void{
            var t:TextField=new TextField();
            t.name=name;
            t.x=x;
            t.y=y;
            t.text=txt;
            addChild(t);
            t.selectable=false;
            t.mouseEnabled=false;
            t.multiline=true;
            t.wordWrap=true;
        }

        //显示消息;
        private function log(str:String):void{
            var tf:TextField=getChildByName("msg") as TextField;
            tf.appendText(str+"\n");
            tf.scrollV=tf.maxScrollV;//滚动
        }

        //===============================================建立全局坐标;
        private function create_coordinate():void {
            coordinate=new Array();
            for (var i:int=0; i<GRID_HTOTAL; i++)
            {
                coordinate.push(new Array(GRID_VTOTAL));
                for (var j:int=0; j<GRID_VTOTAL; j++) {
                    coordinate[i][j] =true;//true为可行走点
                }
            }
        }

        //================================================鼠标点击;
        private function clk(e:MouseEvent) {   //删除定时器
            clearInterval(InID);
            //目标点的坐标
            tx = e.localX / GRID_WIDTH;
            ty = e.localY / GRID_HEIGHT;

            //判断目标点是否障碍物;
            if (coordinate[tx][ty]) {
                path =new Array();//初始化路径
                //获取开始点的坐标;
                nx=player.x/GRID_WIDTH;
                ny=player.y/GRID_HEIGHT;
                //初始化
                Node=new Object();//节点
                closeList=new Object();	//关闭列表
                openList =new Array();//开放列表;
                flag = true;
                var time:uint = getTimer();
                seekRoad();
                log("用时："+String(getTimer()-time)+"ms");
                InID = setInterval(walk,50);
            }else{
                log("目标点不可到达");
            }

        }

        //====================================================开始寻路;
        private function seekRoad() {
            //移除侦听
            //scene.removeEventListener(MouseEvent.CLICK,clk);
            //创建开始节点
            Node = createNode(nx,ny,0,null);
            //把开始节放入关闭列表;
            closeList[Node.nx + "_" + Node.ny] = Node;
            var count:int=0;
            //开始循环;

            while (true) {
                if (nx == tx && ny == ty) {   //循环取父节点;
                    while(Node!=null){
                        //把节点加入到路径
                        path.push(Node);
                        //取父节点
                        Node=Node.pNode;
                    }
                    //退出循环;
                    break;
                }

                //创建八方向节点加入到开放列表；
                pushOpenList(createNode(nx  ,ny+1,10,Node));//下
                pushOpenList(createNode(nx-1,ny+1,14,Node));//左下
                pushOpenList(createNode(nx-1,ny  ,10,Node));//左
                pushOpenList(createNode(nx-1,ny-1,14,Node));//左上
                pushOpenList(createNode(nx  ,ny-1,10,Node));//上
                pushOpenList(createNode(nx+1,ny-1,14,Node));//右上
                pushOpenList(createNode(nx+1,ny  ,10,Node));//右
                pushOpenList(createNode(nx+1,ny+1,14,Node));//右下
                //如果开放列表为空，退出循环
                if (openList.length == 0) {
                    log("目标不可到达");
                    break;
                }
                //计数;
                count++;
                //排序取出f值最小的节点;
                openList.sortOn("f",Array.NUMERIC);
                Node = openList.shift();
                //把当前节点坐标设为下次循环的开始点坐标;
                nx = Node.nx;
                ny = Node.ny;
                closeList[Node.nx + "_" + Node.ny] = Node;//把节点放到关闭列表;
            }

            path.reverse(); //倒序排列
            log("搜索次数："+count.toString());
            log("路径点数："+path.length.toString());
            //清空释放内存;
            Node=null;
            closeList=null;
            openList=null;

        }
        //==============================================加入开放列表;
        private function pushOpenList(nd:Object) {
            if (nd != null) {
                openList.push(nd);
                openList[nd.nx+"_"+nd.ny]=nd;
            }
        }

        //===============================================================创建节点；
        private function createNode(ix:int,iy:int,ng:int,pnd:Object):Object {
            //判断是否出格，是否障碍物，是否关闭或已开启；
            if (ix < 0 || iy < 0 || ix >= GRID_HTOTAL || iy >= GRID_VTOTAL || !coordinate[ix][iy]|| closeList[ix + "_" + iy]||openList[ix+"_"+iy])
            {
                return null;
            }
            var node:Object=new Object();
            node.h = (Math.abs(tx-ix)+Math.abs(ty-iy))*10;
            if(pnd){
                //判断走斜角时上下左右是否有障碍物;
                if(ng==14){
                    if(!coordinate[pnd.nx][iy]||!coordinate[ix][pnd.ny]){
                        return null
                    }
                }
                node.g = ng + pnd.g;
                node.f = node.g + node.h;
            }else{
                node.g=0;
                node.h=0;
                node.f=0
            }
            node.nx = ix;
            node.ny = iy;
            node.pNode = pnd;

            return node;
        }

        //===============================================移动目标;
        private function walk():void {
            if (path.length == 0) {
                clearInterval(InID);
                //scene.addEventListener(MouseEvent.CLICK,clk);
            } else {
                var obj:Object = path.shift();
                player.x = obj.nx * GRID_WIDTH;
                player.y = obj.ny * GRID_HEIGHT;
                obj=null;
                //绘制路径
                if (flag) {
                    flag = false;
                    drawpath.graphics.clear();
                    drawpath.graphics.lineStyle(2,0xff00ff);
                    drawpath.graphics.moveTo(player.x+GRID_WIDTH/2,player.y+GRID_HEIGHT/2);
                } else {
                    drawpath.graphics.lineTo(player.x+GRID_WIDTH/2,player.y+GRID_WIDTH/2);
                }
            }
        }

        //=======================================================创建方格场景;
        private function create_scene()
        {
            scene = new Sprite  ;
            addChild(scene);
            var grap:Graphics=scene.graphics;
            grap.beginFill(0xffffff,1);
            grap.lineStyle(0,0xcccccc);
            grap.drawRect(0,0,WIDTH_TOTAL,HEIGHT_TOTAL);
            //画横线
            for (var i:int=1; i<GRID_VTOTAL; i++) {
                grap.moveTo(0,i*GRID_HEIGHT);
                grap.lineTo(WIDTH_TOTAL,i*GRID_HEIGHT);
                grap.endFill();

            }
            //画竖线
            for (var j:int=1; j<GRID_HTOTAL; j++)
            {
                grap.moveTo(j*GRID_WIDTH,0);
                grap.lineTo(j*GRID_WIDTH,HEIGHT_TOTAL);
                grap.endFill();
            }
        }

        //===================================================创建随机控制点
        private function create_player():void {
            nx = int(Math.random() * GRID_HTOTAL);//宽度范围内随机X坐标;
            ny = int(Math.random() * GRID_VTOTAL);//高度范围内随机Y坐标;
            //判断坐标上是否有障碍物
            if (!coordinate[nx][ny]) {
                create_player();//如有障碍物重新再来
            } else {   player=new Sprite();
                addChild(player);
                player.graphics.beginFill(0x0000ff,1);
                player.graphics.lineStyle(1,0x000000);
                player.graphics.drawRect(0,0,GRID_WIDTH,GRID_HEIGHT);
                player.graphics.endFill();
                player.x = nx * GRID_WIDTH;
                player.y = ny * GRID_HEIGHT;
            }
        }

        //==================================================创建随机障碍物
        private function create_nc():void {
            var nc:Sprite=new Sprite();//障碍物
            nc.name="nc";
            addChild(nc);
            for (var i:int=1; i<NC_COUNT; i++)
            {
                var ncx:int = int(Math.random() * GRID_HTOTAL);
                var ncy:int = int(Math.random() * GRID_VTOTAL);
                nc.graphics.beginFill(0xff5555,1);
                nc.graphics.lineStyle(1,0xcccccc);
                nc.graphics.drawRect(ncx * GRID_WIDTH,ncy * GRID_HEIGHT,GRID_WIDTH,GRID_HEIGHT);
                nc.graphics.endFill();
                coordinate[ncx][ncy] = false;//设置障碍物坐标，false为不可行走点;
            }
        }

        //==============================================重置;
        private function btclk(e:MouseEvent):void {
            removeChild(getChildByName("nc"));//先删除障碍层
            removeChild(player);//删除控制点;
            drawpath.graphics.clear();//清除路径;
            create_coordinate();//重新建立全局坐标;
            create_nc();//障碍物
            create_player();//控制点
        }
    }
}
