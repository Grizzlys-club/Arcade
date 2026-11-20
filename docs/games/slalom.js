(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
class SlalomGame extends MiniScene{
 coneTex(){const cd=this.coneD,d=cd*1.7;return Gfx.texture('slalom_cone_'+Math.floor(cd),d,d,2,c=>{const cx=d/2,r=cd/2;const g=c.createRadialGradient(cx,cx,0,cx,cx,d/2);g.addColorStop(0,'rgba(255,128,26,.55)');g.addColorStop(1,'rgba(255,128,26,0)');c.fillStyle=g;c.fillRect(0,0,d,d);
  const e=(col,k)=>{c.fillStyle=col;c.beginPath();c.arc(cx,cx,r*k,0,7);c.fill()};e('rgb(255,115,13)',1);e('#fff',.72);e('rgb(255,102,0)',.42);e('rgb(153,38,0)',.16)})}
 setupGame(){this.duration=45;const s0=this.seats[0];this.sc=s0.w>300?1:.62;this.pr=15*this.sc;this.coneD=26*this.sc;this.gapW=this.pr*2*2.5;this.rowSp=Math.max(110,s0.h*.34);this.fieldW=s0.w-16;this.puckY=-s0.h/2+74;
  const r=this.newRand();let sign=r.chance(.5)?1:-1;this.gateF=[];for(let i=0;i<220;i++){this.gateF.push(sign*r.range(.4,1));sign=-sign}
  this.lanes=[];for(const s of this.seats)this.buildLane(s)}
 buildLane(s){const L={seat:s,content:new Node(),rows:[],lines:[],puck:new Node(),px:0,tx:0,grab:0,scroll:0,slow:1,combo:0,nextSpawn:0,trailT:0,cpuDelay:0,lastX:0};s.field.add(L.content);
  for(const sx of[-1,1]){const rail=new Sprite(Gfx.rect(3,s.h,s.color),3,s.h);rail.x=sx*this.fieldW/2;rail.alpha=.55;rail.z=1;L.content.add(rail);const g=new Sprite(Gfx.glow(),26,s.h*1.1);g.color=s.color;g.cbf=1;g.blend='add';g.alpha=.35;g.x=rail.x;g.z=1;L.content.add(g)}
  const n=Math.floor(s.h/44)+2;for(let i=0;i<n;i++){const l=new Sprite(Gfx.rect(this.fieldW,2,'#fff'),this.fieldW,2);l.alpha=.07;L.content.add(l);L.lines.push(l)}
  const pr=this.pr,glow=new Sprite(Gfx.glow(),pr*5,pr*5);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.8;L.glow=glow;L.puck.add(glow);
  const disc=new Sprite(Gfx.circle(pr,white(.08),s.color),pr*2,pr*2);disc.z=1;L.puck.add(disc);
  const bear=this.makeBear(s,40*this.sc,s.index%2===0);bear.y=-pr*.35;bear.z=3;L.puck.add(bear);L.bear=bear;L.puck.y=this.puckY;L.puck.z=30;L.content.add(L.puck);
  const cl=label('',13*Math.max(this.sc,.85),rgba(.4,1,.9));cl.ha='left';cl.x=-s.w/2+14;cl.y=-s.h/2+14;cl.z=400;s.node.add(cl);L.comboLabel=cl;
  if(!s.isCPU){const hint=label('← WISCHEN →',15*Math.max(this.sc,.85),'#fff');hint.y=-s.h/2+22;hint.z=420;s.node.add(hint);hint.run(A.sequence([A.wait(4.5),A.fadeOut(.5),A.remove()]))}
  this.lanes.push(L);this.updateLines(L);this.spawnRows(L)}
 rowY(L,k){return this.puckY+170+k*this.rowSp-L.scroll}
 spawnRows(L){const top=L.seat.h/2+60;while(true){const y=this.rowY(L,L.nextSpawn);if(y>top)break;this.makeRow(L,L.nextSpawn);L.nextSpawn++}}
 makeRow(L,k){const row={node:new Node(),k,cones:[],done:false,hit:false},maxG=this.fieldW/2-this.gapW/2-this.coneD*1.3;row.gx=this.gateF[k%this.gateF.length]*maxG;row.gl=row.gx-this.gapW/2;row.gr=row.gx+this.gapW/2;
  const tex=this.coneTex(),sp=this.coneD*1.02,cd=this.coneD;
  const add=x=>{const c=new Sprite(tex,cd*1.7,cd*1.7);c.x=x;row.node.add(c);row.cones.push(c)};
  for(let x=row.gl-cd/2;x>-this.fieldW/2+cd*.4;x-=sp)add(x);for(let x=row.gr+cd/2;x<this.fieldW/2-cd*.4;x+=sp)add(x);
  const beam=new Sprite(Gfx.glow(),this.gapW*1.5,cd*2.2);beam.color=rgba(.3,1,.6);beam.cbf=1;beam.blend='add';beam.alpha=.4;beam.x=row.gx;beam.z=2;row.node.add(beam);row.beam=beam;
  const sk=Math.max(.1,L.seat.skill),std=(1-sk)*this.gapW*.45,e=(Math.random()*2-1+Math.random()*2-1)*.5*std*1.6,lim=this.gapW*.5*1.15;row.err=Math.max(-lim,Math.min(lim,e));
  row.y=this.rowY(L,k);row.node.y=row.y;row.node.z=10;L.content.add(row.node);L.rows.push(row)}
 updateLines(L){const h=L.seat.h,span=L.lines.length*44;L.lines.forEach((l,i)=>{let y=(i*44-L.scroll)%span;if(y<0)y+=span;l.x=0;l.y=y-h/2-22})}
 gameStarted(){for(const L of this.lanes)L.bear.startBob(2,.25)}
 began(seat,at){const L=this.lanes[seat.index];L.grab=L.px-at.x;L.tx=L.px}
 moved(seat,at){const L=this.lanes[seat.index];L.tx=at.x+L.grab}
 gameUpdate(dt){const maxX=this.fieldW/2-this.pr-2,pr=this.pr,puckY=this.puckY;
  for(const L of this.lanes){const s=L.seat,ramp=Math.min(1,this.elapsed/40),base=(150+175*ramp)*(this.sc>.9?1:.9);L.slow=Math.min(1,L.slow+dt*.6);L.scroll+=base*L.slow*dt;
   if(s.isCPU){const next=L.rows.find(r=>!r.done);let target=0;if(next)target=next.gx+next.err;if(L.cpuDelay>0)L.cpuDelay-=dt;else L.tx=target;const maxv=(260+560*s.skill)*this.sc,d=L.tx-L.px;L.px+=Math.max(-maxv*dt,Math.min(maxv*dt,d))}
   else L.px+=(L.tx-L.px)*Math.min(1,dt*22);
   L.px=Math.max(-maxX,Math.min(maxX,L.px));const vx=(L.px-L.lastX)/Math.max(dt,.001);L.lastX=L.px;L.puck.x=L.px;L.puck.y=puckY;
   L.bear.rot+=(Math.max(-.35,Math.min(.35,-vx*.0006))-L.bear.rot)*Math.min(1,dt*12);L.glow.alpha=.55+.3*L.slow;
   L.trailT-=dt;if(L.trailT<=0){L.trailT=.045;const t=new Sprite(Gfx.dot(),pr*1.1,pr*1.1);t.color=s.color;t.cbf=1;t.blend='add';t.alpha=.7;t.x=L.px;t.y=puckY-pr*.6;t.z=25;L.content.add(t);t.run(A.sequence([A.group([A.moveBy(0,-50*L.slow,.35),A.fadeOut(.35),A.scaleTo(.2,.35)]),A.remove()]))}
   this.updateLines(L);
   for(const r of L.rows){r.y=this.rowY(L,r.k);r.node.y=r.y;if(r.done)continue;const dy=r.y-puckY,reach=this.coneD/2+pr*.7;
    if(Math.abs(dy)<reach&&!r.hit){if(L.px-pr*.8<r.gl||L.px+pr*.8>r.gr){r.hit=true;this.hitCone(L,r)}}
    if(dy<-reach){r.done=true;if(!r.hit)this.passGate(L,r);L.cpuDelay=(1-s.skill)*.22}}
   while(L.rows.length&&L.rows[0].y<-s.h/2-50){L.rows[0].node.removeFromParent();L.rows.shift()}
   this.spawnRows(L)}}
 hitCone(L,r){const s=L.seat;r.done=true;L.combo=0;L.comboLabel.text='';L.slow=.25;let best=null,bd=1e9;for(const c of r.cones){if(c.alpha>.5){const d=Math.abs(c.x-L.px);if(d<bd){bd=d;best=c}}}
  if(best){const dir=best.x<L.px?-1:1;best.run(A.group([A.moveBy(dir*60,90,.5),A.rotateBy(dir*6,.5),A.fadeOut(.5)]))}
  r.beam.alpha=.05;s.shake(5);s.flash('#f00',.25,.3);s.burst({x:L.px,y:this.puckY+this.pr},rgba(1,.5,.1),16,120);s.floatText('AUA',{x:L.px,y:this.puckY+40*this.sc},rgba(1,.35,.3),18);L.bear.squash();
  L.puck.run(A.sequence([A.moveBy(0,-8,.05),A.moveBy(0,8,.12)]));if(!s.isCPU){Sfx.play('hit');Haptic.bad()}}
 passGate(L,r){const s=L.seat;L.combo++;const pts=1+(L.combo>=3?Math.floor(Math.min(L.combo-1,12)/3):0);this.addScore(s,pts);r.beam.removeAllActions();r.beam.alpha=1;r.beam.run(A.fadeTo(.12,.5));
  s.floatText('+'+pts,{x:L.px,y:this.puckY+36*this.sc},rgba(.4,1,.6),pts>1?22:18);s.burst({x:r.gx,y:this.puckY},rgba(.4,1,.7),8,80);
  if(L.combo>=3){L.comboLabel.text='KOMBO x'+L.combo;L.comboLabel.removeAllActions();L.comboLabel.run(A.sequence([A.scaleTo(1.3,.06),A.scaleTo(1,.1)]))}
  if(L.combo>0&&L.combo%5===0){s.floatText('KOMBO x'+L.combo+'!',{x:0,y:this.puckY+90*this.sc},rgba(1,.9,.2),22);s.burst({x:L.px,y:this.puckY+20},rgba(1,.9,.2),26,170);L.bear.celebrate();s.flash('#ff0',.12);if(!s.isCPU){Sfx.play('right');Haptic.good()}}
  else if(!s.isCPU){Sfx.play('coin');Haptic.tap()}}
}
Arcade.register('slalom',SlalomGame);
})();
