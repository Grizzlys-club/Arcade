(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const GRAV=-1150,JUMP=560,BH=30;
class HopperGame extends MiniScene{
 platW(s){return Math.min(64,s.w*.3)}
 setupGame(){this.duration=60;this.states=[];
  for(const s of this.seats){const bear=this.makeBear(s,BH,true),st={seat:s,rand:this.newRand(),cam:new Node(),bear,plats:[],x:0,y:0,vx:0,vy:0,camY:0,lastY:0,targetX:null,landY:0,cpuTimer:0,height:0};s.field.add(st.cam);st.cam.z=5;
   const y0=-s.h/2+34;this.addPlat(st,0,y0,'normal',s.w*.6);st.lastY=y0;st.landY=y0;st.x=0;st.y=y0;bear.x=0;bear.y=y0+6;bear.z=20;st.cam.add(bear);this.generate(st);
   const hint=label(s.isCPU?'CPU':'FINGER ← → ZIEHEN',s.w>300?18:12,white(1,.85));hint.z=40;s.field.add(hint);hint.run(A.sequence([A.wait(4.6),A.fadeOut(.4),A.remove()]));this.states.push(st)}}
 gameStarted(){for(const st of this.states)st.vy=JUMP}
 addPlat(st,x,y,kind,width,amp,phase){const s=st.seat,pw=width||this.platW(s);let fill,border;
  if(kind==='normal'){fill=s.color;border='#fff'}else if(kind==='moving'){fill=rgba(.3,.85,1);border='#fff'}else{fill=rgba(.45,.3,.2);border=rgba(.8,.55,.3)}
  const node=new Sprite(Gfx.pill(pw,14,fill,border,7),pw,14);node.x=x;node.y=y-7;st.cam.add(node);
  if(kind==='breaking'){const crack=label('⚡︎',10,white(0,.6));crack.z=1;node.add(crack)}else{const glow=new Sprite(Gfx.glow(),pw*1.4,26);glow.color=fill;glow.cbf=1;glow.blend='add';glow.alpha=.35;glow.z=-1;node.add(glow)}
  st.plats.push({node,x,baseX:x,y,kind,amp:amp||0,phase:phase||0,broken:false})}
 generate(st){const s=st.seat,pw=this.platW(s),half=s.w/2-pw/2-6;
  while(st.lastY<st.camY+s.h){const hardness=Math.min(1,Math.max(0,st.lastY)/4000),gap=st.rand.range(42,62+40*hardness);st.lastY+=gap;const x=st.rand.range(-half,half),r=st.rand.double();
   if(r<.18+.2*hardness){const amp=st.rand.range(20,Math.max(22,half));this.addPlat(st,0,st.lastY,'moving',null,Math.min(amp,half),st.rand.range(0,6.28))}else this.addPlat(st,x,st.lastY,'normal');
   if(st.rand.chance(.22+.15*hardness)){const bx=st.rand.range(-half,half);this.addPlat(st,bx,st.lastY+gap*.5,'breaking')}}}
 gameUpdate(dt){const t=this.elapsed;
  for(const st of this.states){const s=st.seat;if(!s.alive)continue;
   for(const p of st.plats)if(p.kind==='moving'){p.x=p.baseX+Math.sin(t*1.6+p.phase)*p.amp;p.node.x=p.x}
   if(s.isCPU)this.cpuThink(st,dt);
   if(st.targetX!=null)st.vx=Math.max(-340,Math.min(340,(st.targetX-st.x)*8));else st.vx*=(1-Math.min(1,5*dt));
   const prevY=st.y;st.vy+=GRAV*dt;st.x+=st.vx*dt;st.y+=st.vy*dt;const lim=s.w/2-10;st.x=Math.max(-lim,Math.min(lim,st.x));
   if(st.vy<0){for(const p of st.plats){if(p.broken)continue;const pw=p.node.w;
     if(prevY>=p.y-1&&st.y<=p.y&&Math.abs(st.x-p.x)<pw/2+8){
      if(p.kind==='breaking'){p.broken=true;p.node.run(A.sequence([A.group([A.moveBy(0,-120,.5),A.fadeOut(.5),A.rotateBy(.8,.5)]),A.remove()]));if(!s.isCPU)Sfx.play('miss');continue}
      st.y=p.y;st.vy=JUMP;st.landY=p.y;st.bear.squash();if(!s.isCPU)Sfx.play('bounce');break}}}
   st.bear.x=st.x;st.bear.y=st.y;if(Math.abs(st.vx)>20)st.bear.setFacing(st.vx>0);
   const follow=st.y-s.h*.05;if(follow>st.camY)st.camY=follow;st.cam.y=-st.camY;
   const hgt=Math.floor(Math.max(0,st.camY)/10);if(hgt!==st.height){st.height=hgt;s.score=hgt;if(s.scoreLabel)s.scoreLabel.text=''+hgt}
   this.generate(st);
   st.plats=st.plats.filter(p=>{if(p.y<st.camY-s.h/2-60){p.node.removeFromParent();return false}return true});
   if(st.y<st.camY-s.h/2-30)this.fall(st)}
  this.checkEnd()}
 fall(st){const s=st.seat;s.knockOut('ABGESTÜRZT');Sfx.play('lose');if(!s.isCPU)Haptic.bad();s.flash('#f00',.3)}
 cpuThink(st,dt){st.cpuTimer-=dt;if(st.cpuTimer>0)return;const s=st.seat;st.cpuTimer=.08+(1-s.skill)*.25;const apex=st.y+(st.vy>0?st.vy*st.vy/(2*-GRAV):0),allowTrap=Math.random()<(1-s.skill)*.3;let best=null;
  for(const p of st.plats){if(p.broken||(p.kind==='breaking'&&!allowTrap))continue;if(p.y<=apex-6&&p.y>st.landY+4){if(!best||p.y>best.y)best=p}}
  if(!best)for(const p of st.plats){if(p.broken||p.kind==='breaking'||!(p.y<st.y))continue;if(!best||p.y>best.y)best=p}
  if(best){const noise=(Math.random()*2-1)*(1-s.skill)*best.node.w*.9;st.targetX=best.x+noise}}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others+5)this.finishGame()}}
 began(seat,at){const st=this.states.find(s=>s.seat===seat);if(st)st.targetX=at.x}
 moved(seat,at){const st=this.states.find(s=>s.seat===seat);if(st)st.targetX=at.x}
 ended(seat){const st=this.states.find(s=>s.seat===seat);if(st)st.targetX=null}
}
Arcade.register('hopper',HopperGame);
})();
