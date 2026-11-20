(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const R=(x,y,w,h)=>({x,y,w,h});
const COURSES=[
 {start:[.5,.12],hole:[.5,.85],walls:[R(.3,.46,.4,.05)]},
 {start:[.2,.12],hole:[.8,.86],walls:[R(0,.38,.62,.05),R(.38,.64,.62,.05)]},
 {start:[.5,.1],hole:[.5,.86],walls:[R(.1,.42,.3,.05),R(.6,.42,.3,.05),R(.44,.66,.12,.12)]},
 {start:[.8,.12],hole:[.18,.82],walls:[R(.35,.25,.06,.45),R(0,.6,.25,.05),R(.6,.7,.4,.05)]},
 {start:[.5,.1],hole:[.5,.6],walls:[R(.25,.52,.05,.2),R(.7,.52,.05,.2),R(.25,.72,.5,.05),R(0,.32,.4,.04)]},
 {start:[.15,.1],hole:[.85,.5],walls:[R(.55,0,.05,.42),R(.55,.58,.05,.42),R(.2,.55,.2,.05)]},
 {start:[.5,.1],hole:[.8,.85],walls:[R(.2,.3,.12,.12),R(.62,.3,.12,.12),R(.42,.55,.12,.12),R(.6,.72,.05,.28)]}];
const PR=9,HR=13,GREEN=rgba(.3,1,.5);
const puckTex=()=>Gfx.texture('golf_puck',40,40,2,c=>{c.fillStyle='rgb(15,15,15)';c.beginPath();c.arc(20,20,18,0,7);c.fill();c.strokeStyle=Theme.orange;c.lineWidth=4;c.beginPath();c.arc(20,20,16,0,7);c.stroke();c.fillStyle='rgba(255,255,255,.35)';c.beginPath();c.ellipse(17,12.5,6,3.5,0,0,7);c.fill()});
const holeTex=()=>Gfx.texture('golf_hole',60,60,2,c=>{c.fillStyle='#000';c.beginPath();c.arc(30,30,24,0,7);c.fill();c.strokeStyle=GREEN;c.lineWidth=4;c.beginPath();c.arc(30,30,26,0,7);c.stroke()});
class PuckGolfGame extends MiniScene{
 setupGame(){this.duration=60;this.st=[];
  for(const s of this.seats){const g={play:{x:-s.w/2+10,y:-s.h/2+10,w:s.w-20,h:s.h-50},courseIndex:0,walls:[],hole:{x:0,y:0},pos:{x:0,y:0},vel:{x:0,y:0},strokes:0,dragging:false,sinking:false,cpuWait:1,courseNode:new Node(),aimDots:[],holesDone:0};
   const pl=g.play,floor=new Sprite(Gfx.pill(pl.w+8,pl.h+8,rgba(.08,.22,.16,.9),alpha(GREEN,.8),14),pl.w+8,pl.h+8);floor.x=pl.x+pl.w/2;floor.y=pl.y+pl.h/2;floor.z=-5;s.field.add(floor);
   for(let y=pl.y+30;y<pl.y+pl.h;y+=44){const line=new Sprite(null,pl.w,14,white(1,.04));line.x=pl.x+pl.w/2;line.y=y;line.z=-4;s.field.add(line)}
   g.courseNode.z=1;s.field.add(g.courseNode);g.puck=new Sprite(puckTex(),PR*2+2,PR*2+2);g.puck.z=10;s.field.add(g.puck);
   g.aim=new Node();g.aim.z=9;s.field.add(g.aim);for(let i=0;i<9;i++){const d=new Sprite(Gfx.dot(),7,7);d.color=s.color;d.cbf=1;d.alpha=1-i*.09;g.aim.add(d);g.aimDots.push(d)}g.aim.hidden=true;
   g.strokeLabel=label('SCHLÄGE 0',12,white(1,.75));g.strokeLabel.ha='left';g.strokeLabel.x=-s.w/2+14;g.strokeLabel.y=s.h/2-34;g.strokeLabel.z=20;s.node.add(g.strokeLabel);
   g.holeLabel=label('LOCH 1',12,GREEN);g.holeLabel.ha='right';g.holeLabel.x=s.w/2-14;g.holeLabel.y=s.h/2-34;g.holeLabel.z=20;s.node.add(g.holeLabel);
   this.st.push(g);this.loadCourse(s,0);
   const hint=label('ZIEHEN & LOSLASSEN',Math.min(16,s.w*.075),'#fff');hint.y=-s.h/2+70;hint.z=30;s.field.add(hint);hint.run(A.sequence([A.wait(5.5),A.fadeOut(.4),A.remove()]))}}
 moving(g){return Math.hypot(g.vel.x,g.vel.y)>0}
 P(g,u){return{x:g.play.x+u[0]*g.play.w,y:g.play.y+u[1]*g.play.h}}
 loadCourse(s,idx){const g=this.st[s.index];g.courseIndex=idx;const c=COURSES[idx%COURSES.length];g.courseNode.children.slice().forEach(ch=>ch.removeFromParent());
  g.walls=c.walls.map(r=>({x:g.play.x+r.x*g.play.w,y:g.play.y+r.y*g.play.h,w:Math.max(10,r.w*g.play.w),h:Math.max(10,r.h*g.play.h)}));
  for(const r of g.walls){const wn=new Sprite(Gfx.pill(r.w,r.h,rgba(.18,.18,.3),alpha(s.color,.9),4),r.w,r.h);wn.x=r.x+r.w/2;wn.y=r.y+r.h/2;g.courseNode.add(wn)}
  g.hole=this.P(g,c.hole);const glow=new Sprite(Gfx.glow(),70,70);glow.color=GREEN;glow.cbf=1;glow.blend='add';glow.alpha=.5;glow.x=g.hole.x;glow.y=g.hole.y;g.courseNode.add(glow);glow.run(A.forever(A.sequence([A.fadeTo(.25,.6),A.fadeTo(.55,.6)])));
  const hole=new Sprite(holeTex(),HR*2+4,HR*2+4);hole.x=g.hole.x;hole.y=g.hole.y;g.courseNode.add(hole);
  const pole=new Sprite(null,2,26,'#fff');pole.ay=0;pole.x=g.hole.x+2;pole.y=g.hole.y;g.courseNode.add(pole);
  const flag=new Sprite(null,14,9,s.color);flag.ax=0;flag.x=g.hole.x+3;flag.y=g.hole.y+21;g.courseNode.add(flag);flag.run(A.forever(A.sequence([A.scaleXTo(.7,.3),A.scaleXTo(1,.3)])));
  g.pos=this.P(g,c.start);g.vel={x:0,y:0};g.strokes=0;g.sinking=false;g.dragging=false;g.aim.hidden=true;g.cpuWait=.9+(1-s.skill)*.8;g.puck.x=g.pos.x;g.puck.y=g.pos.y;g.puck.setScale(.1);g.puck.alpha=1;g.puck.run(A.scaleTo(1,.25));
  g.strokeLabel.text='SCHLÄGE 0';g.holeLabel.text='LOCH '+(g.holesDone+1)}
 pstep(o,dt,g){const dx=g.hole.x-o.pos.x,dy=g.hole.y-o.pos.y,d=Math.hypot(dx,dy),speed=Math.hypot(o.vel.x,o.vel.y);if(d<HR&&speed<330)return true;
  if(d<HR*2.2&&d>.1){const pull=900*(1-d/(HR*2.2));o.vel.x+=dx/d*pull*dt;o.vel.y+=dy/d*pull*dt}
  const k=Math.max(0,1-1.25*dt);o.vel.x*=k;o.vel.y*=k;const sp=Math.hypot(o.vel.x,o.vel.y);if(sp<14){o.vel.x=0;o.vel.y=0;return false}
  if(sp>0){const dec=Math.min(sp,40*dt);o.vel.x-=o.vel.x/sp*dec;o.vel.y-=o.vel.y/sp*dec}
  o.pos.x+=o.vel.x*dt;o.pos.y+=o.vel.y*dt;const b=g.play;
  if(o.pos.x<b.x+PR){o.pos.x=b.x+PR;o.vel.x=Math.abs(o.vel.x)*.8}if(o.pos.x>b.x+b.w-PR){o.pos.x=b.x+b.w-PR;o.vel.x=-Math.abs(o.vel.x)*.8}
  if(o.pos.y<b.y+PR){o.pos.y=b.y+PR;o.vel.y=Math.abs(o.vel.y)*.8}if(o.pos.y>b.y+b.h-PR){o.pos.y=b.y+b.h-PR;o.vel.y=-Math.abs(o.vel.y)*.8}
  for(const r of g.walls){const cx=Math.max(r.x,Math.min(o.pos.x,r.x+r.w)),cy=Math.max(r.y,Math.min(o.pos.y,r.y+r.h)),ex=o.pos.x-cx,ey=o.pos.y-cy,dist=Math.hypot(ex,ey);
   if(dist<PR){let nx=0,ny=0;if(dist>.001){nx=ex/dist;ny=ey/dist}else{const l=o.pos.x-r.x,rr=r.x+r.w-o.pos.x,bb=o.pos.y-r.y,t=r.y+r.h-o.pos.y,m=Math.min(l,rr,bb,t);if(m===l)nx=-1;else if(m===rr)nx=1;else if(m===bb)ny=-1;else ny=1}
    o.pos.x=cx+nx*PR;o.pos.y=cy+ny*PR;const vn=o.vel.x*nx+o.vel.y*ny;if(vn<0){o.vel.x-=1.8*vn*nx;o.vel.y-=1.8*vn*ny;o.bounced=true}}}
  return false}
 simulate(g,from,v0){const o={pos:{x:from.x,y:from.y},vel:{x:v0.x,y:v0.y}};let best=1e9;for(let i=0;i<300;i++){if(this.pstep(o,1/60,g))return[0,true];best=Math.min(best,Math.hypot(o.pos.x-g.hole.x,o.pos.y-g.hole.y)*.3);if(o.vel.x===0&&o.vel.y===0)break}return[Math.hypot(o.pos.x-g.hole.x,o.pos.y-g.hole.y)+best*.2,false]}
 shoot(s,v){const g=this.st[s.index];g.vel={x:v.x,y:v.y};g.strokes++;g.strokeLabel.text='SCHLÄGE '+g.strokes;Sfx.play('kick');if(!s.isCPU)Haptic.tap();g.puck.run(A.sequence([A.scaleTo(1.25,.05),A.scaleTo(1,.1)]));s.burst(g.pos,s.color,6,70)}
 sink(s){const g=this.st[s.index];g.sinking=true;g.vel={x:0,y:0};const pts=Math.max(1,6-g.strokes);this.addScore(s,pts);this.addStat('goals',1,s);g.holesDone++;
  g.puck.run(A.group([A.moveTo(g.hole.x,g.hole.y,.15),A.scaleTo(.2,.25),A.fadeOut(.25)]));s.burst(g.hole,GREEN,24,130);
  s.floatText(g.strokes===1?'HOLE IN ONE! +'+pts:'+'+pts,{x:g.hole.x,y:g.hole.y+20},g.strokes===1?'#ff0':GREEN,g.strokes===1?18:24);
  if(g.strokes===1){s.flash('#ff0',.25);s.shake(5)}Sfx.play(g.strokes===1?'fanfare':'goal');if(!s.isCPU)Haptic.good();
  this.run(A.sequence([A.wait(.9),A.run(()=>{if(this.phase==='playing')this.loadCourse(s,g.courseIndex+1)})]))}
 skipHole(s){const g=this.st[s.index];g.sinking=true;s.floatText('ZU VIELE SCHLÄGE',g.pos,white(1,.8),14);Sfx.play('miss');this.run(A.sequence([A.wait(.8),A.run(()=>{if(this.phase==='playing')this.loadCourse(s,g.courseIndex+1)})]))}
 gameUpdate(dt){for(const s of this.seats){const g=this.st[s.index];if(g.sinking)continue;
   if(this.moving(g)){let sunk=false;g.bounced=false;for(let i=0;i<2;i++){if(this.pstep(g,dt/2,g)){sunk=true;break}}
    g.puck.x=g.pos.x;g.puck.y=g.pos.y;g.puck.rot+=Math.hypot(g.vel.x,g.vel.y)*dt*.02;
    if(g.bounced&&Math.hypot(g.vel.x,g.vel.y)>80)Sfx.play('tick');
    if(sunk){this.sink(s);continue}if(!this.moving(g)&&g.strokes>=8)this.skipHole(s)}
   else if(s.isCPU){g.cpuWait-=dt;if(g.cpuWait<=0)this.cpuShot(s)}}}
 cpuShot(s){const g=this.st[s.index];let bestV={x:0,y:300},bestScore=1e9;const base=Math.atan2(g.hole.y-g.pos.y,g.hole.x-g.pos.x);
  for(let i=0;i<28;i++){const a=base+i/28*2*Math.PI;for(const pw of[330,520,720,900]){const v={x:Math.cos(a)*pw,y:Math.sin(a)*pw},[score,sunk]=this.simulate(g,g.pos,v),sc=sunk?-pw*.01:score;if(sc<bestScore){bestScore=sc;bestV=v}}}
  const err=(1-s.skill)*.32,a=Math.atan2(bestV.y,bestV.x)+(Math.random()*2-1)*err,pw=Math.hypot(bestV.x,bestV.y)*(1+(Math.random()*2-1)*err*.6),v={x:Math.cos(a)*pw,y:Math.sin(a)*pw};
  this.showAim(g,{x:-v.x/7.5,y:-v.y/7.5});g.aim.run(A.sequence([A.wait(.25),A.hide()]));
  this.run(A.sequence([A.wait(.25),A.run(()=>{if(this.phase==='playing'&&!g.sinking)this.shoot(s,v)})]));g.cpuWait=99;this.run(A.sequence([A.wait(.3),A.run(()=>{g.cpuWait=.8+(1-s.skill)*.9})]))}
 showAim(g,pull){g.aim.hidden=false;const len=Math.hypot(pull.x,pull.y);if(len<1){g.aim.hidden=true;return}const dir={x:-pull.x/len,y:-pull.y/len};
  g.aimDots.forEach((dot,i)=>{const t=(i+1)/g.aimDots.length,dd=len*1.6*t;dot.x=g.pos.x+dir.x*dd;dot.y=g.pos.y+dir.y*dd;dot.setScale(1+len/110*.5)})}
 pullVec(g,at){let v={x:at.x-g.pos.x,y:at.y-g.pos.y};const l=Math.hypot(v.x,v.y),mx=115;if(l>mx){v.x*=mx/l;v.y*=mx/l}return v}
 began(seat,at){const g=this.st[seat.index];if(g.sinking||this.moving(g))return;g.dragging=true;this.showAim(g,this.pullVec(g,at))}
 moved(seat,at){const g=this.st[seat.index];if(!g.dragging)return;this.showAim(g,this.pullVec(g,at))}
 ended(seat,at){const g=this.st[seat.index];if(!g.dragging)return;g.dragging=false;g.aim.hidden=true;if(g.sinking||this.moving(g))return;const v=this.pullVec(g,at);if(Math.hypot(v.x,v.y)<12)return;this.shoot(seat,{x:-v.x*7.8,y:-v.y*7.8})}
}
Arcade.register('puckgolf',PuckGolfGame);
})();
