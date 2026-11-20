(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
class ZigzagGame extends MiniScene{
 speed(s){const k=1+.8*Math.min(1,this.elapsed/45);return s.w*.46*k}limit(s){return s.w/2-14}
 setupGame(){this.duration=45;this.humansSeen=this.seats.some(s=>!s.isCPU);this.st=[];this.endTimer=-1;
  for(const s of this.seats){const g={rand:this.newRand(),items:[],nextY:260,wy:0,x:0,dir:1,world:new Node(),trailT:0,cpuAt:-1,cpuLock:0};this.baseY=-s.h/2+90;s.field.add(g.world);
   for(const side of[-1,1]){const w=new Sprite(Gfx.rect(5,s.h,s.color,2),5,s.h);w.x=side*(s.w/2-4);w.y=0;w.z=20;const gl=new Sprite(Gfx.glow(),40,s.h*1.2);gl.color=s.color;gl.cbf=1;gl.blend='add';gl.alpha=.55;w.add(gl);s.field.add(w)}
   const bh=Math.min(46,s.w*.2);g.bear=this.makeBear(s,bh,true);g.bear.z=30;g.bear.startBob(2,.2);g.bear.x=0;g.bear.y=this.baseY;s.field.add(g.bear);this.st.push(g);
   const hint=label('TIPPEN = WENDEN',Math.min(17,s.w*.08),'#fff');hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]))}
  for(const s of this.seats)this.fill(s)}
 fill(s){const g=this.st[s.index],hw=this.limit(s)-8;
  while(g.nextY<g.wy+s.h+120){const y=g.nextY,r=g.rand;
   if(r.chance(.42)){const side=r.chance(.5)?-1:1,bw=r.range(.2,.42)*s.w,n=new Sprite(Gfx.rect(bw,12,Theme.pink,5),bw,12),gl=new Sprite(Gfx.glow(),bw+26,44);gl.color=Theme.pink;gl.cbf=1;gl.blend='add';gl.alpha=.6;n.add(gl);n.z=10;g.world.add(n);n.x=side*(s.w/2-bw/2-2);n.y=y;g.items.push({node:n,wy:y,x:0,block:true,side,bw,taken:false})}
   else{const count=r.chance(.35)?2:1;for(let k=0;k<count;k++){const x=r.range(-hw,hw),n=new Sprite(Gfx.ball(9),20,20);n.color='rgb(85,85,85)';n.cbf=.7;const gl=new Sprite(Gfx.glow(),40,40);gl.color=Theme.orange;gl.cbf=1;gl.blend='add';gl.alpha=.7;gl.z=-1;n.add(gl);n.z=10;n.x=x;n.y=y+k*34;g.world.add(n);g.items.push({node:n,wy:y+k*34,x,block:false,side:0,bw:0,taken:false})}}
   g.nextY+=r.range(80,125)}}
 flip(s){const g=this.st[s.index];g.dir=-g.dir;g.bear.setFacing(g.dir>0);g.bear.squash();Sfx.play('tap');if(!s.isCPU)Haptic.tap('light')}
 crash(s){const g=this.st[s.index],p={x:g.bear.x,y:g.bear.y};s.burst(p,Theme.pink,20,140);s.flash('#f00',.4);s.shake(9);Sfx.play('lose');if(!s.isCPU)Haptic.bad();g.bear.stopBob();
  g.bear.run(A.group([A.rotateBy(3,.4),A.fadeTo(.3,.4)]));s.knockOut('CRASH')}
 gameUpdate(dt){let alive=0;
  for(const s of this.seats){const g=this.st[s.index];if(!s.alive)continue;alive++;const v=this.speed(s),lim=this.limit(s);
   if(s.isCPU){if(g.cpuAt<0&&this.elapsed>g.cpuLock){let danger=false;const marginT=.05+(1-s.skill)*.3,ahead=g.dir*(g.x+g.dir*v*marginT);if(ahead>=lim-4)danger=true;
     for(const it of g.items){if(!it.block||it.taken||!(it.wy>g.wy-12&&it.wy<g.wy+150))continue;const edge=it.side*(s.w/2-it.bw-4),after=g.x+g.dir*(it.wy-g.wy+v*marginT);if(it.side===g.dir&&after*it.side>edge*it.side-6)danger=true}
     if(danger)g.cpuAt=this.elapsed+Math.random()*(1-s.skill)*.18}
    if(g.cpuAt>=0&&this.elapsed>=g.cpuAt){g.cpuAt=-1;g.cpuLock=this.elapsed+.3;this.flip(s)}}
   g.x+=g.dir*v*dt;g.wy+=v*dt;g.bear.x=g.x;g.bear.y=this.baseY;g.bear.rot=-g.dir*.22;g.world.y=this.baseY-g.wy;
   g.trailT-=dt;if(g.trailT<=0){g.trailT=.05;const tr=new Sprite(Gfx.glow(),22,22);tr.color=s.color;tr.cbf=1;tr.blend='add';tr.alpha=.6;tr.x=g.x;tr.y=g.wy+4;tr.z=5;g.world.add(tr);tr.run(A.sequence([A.group([A.fadeOut(.4),A.scaleTo(.2,.4)]),A.remove()]))}
   const by=g.wy+14;let crashed=Math.abs(g.x)>=lim;
   for(let i=0;i<g.items.length;i++){const it=g.items[i];if(it.taken)continue;if(it.wy<g.wy-60){it.node.removeFromParent();it.taken=true;continue}
    if(it.block){if(Math.abs(it.wy-by)<15&&it.side*g.x>it.side*(it.side*(s.w/2-it.bw-2))-4)crashed=true}
    else if(Math.hypot(it.x-g.x,it.wy-by)<24){it.taken=true;it.node.removeFromParent();this.addScore(s,1);this.addStat('balls',1,s);const p={x:it.x,y:this.baseY+(it.wy-g.wy)};
     s.floatText('+1',p,Theme.orange);s.burst(p,Theme.orange,8,70);Sfx.play('coin');if(!s.isCPU)Haptic.tap('light')}}
   if(g.items.length>60)g.items=g.items.filter(i=>!i.taken);this.fill(s);if(crashed){this.crash(s);alive--}}
  if(this.endTimer<0){const humanAlive=this.seats.some(s=>!s.isCPU&&s.alive);if(alive===0||(this.humansSeen&&!humanAlive))this.endTimer=1}
  else{this.endTimer-=dt;if(this.endTimer<=0)this.finishGame()}}
 began(seat){this.flip(seat)}
}
Arcade.register('zigzag',ZigzagGame);
})();
