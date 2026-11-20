(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const rr=(a,b)=>a+Math.random()*(b-a),PUCKR=13,MAXS=1050;
class AirHockeyGame extends MiniScene{
 static get layout(){return 'arena'}
 static get stripThickness(){return 58}
 setupGame(){this.duration=75;const a=this.arena;this.rink={x:a.x+6,y:a.y+6,w:a.w-12,h:a.h-12};const rk=this.rink;rk.cx=rk.x+rk.w/2;rk.cy=rk.y+rk.h/2;rk.r=rk.x+rk.w;rk.t=rk.y+rk.h;
  this.paddleR=this.n>=3?23:27;this.goalW=Math.min(rk.w,rk.h)*(this.n>=3?.42:.4);this.paddles=[];this.puckPos={x:0,y:0};this.puckVel={x:0,y:0};this.lastTouch=-1;this.puckLive=false;this.trailTimer=0;this.outCount=0;
  const iw=Math.floor(rk.w),ih=Math.floor(rk.h);
  const ice=new Sprite(Gfx.texture('airhockey_ice_'+iw+'x'+ih,iw,ih,1.5,c=>{Gfx.gradientColors(c,rgba(.08,.16,.3),rgba(.05,.09,.2),iw,ih);c.strokeStyle='rgba(102,204,255,.22)';c.lineWidth=2;c.beginPath();c.arc(iw/2,ih/2,48,0,7);c.moveTo(0,ih/2);c.lineTo(iw,ih/2);c.stroke();c.fillStyle='rgba(255,255,255,.06)';for(let y=10;y<ih;y+=18)for(let x=10;x<iw;x+=18)c.fillRect(x,y,2,2)}),rk.w,rk.h);
  ice.x=rk.cx;ice.y=rk.cy;ice.z=-20;this.world.add(ice);
  const d=Math.min(rk.w,rk.h)*.55,logo=new Sprite(Gfx.logo,d,d);logo.x=rk.cx;logo.y=rk.cy;logo.alpha=.1;logo.z=-19;this.world.add(logo);
  const board=new Sprite(Gfx.pill(rk.w,rk.h,'rgba(0,0,0,0)','rgba(128,230,255,.9)',14,false),rk.w,rk.h);board.x=rk.cx;board.y=rk.cy;board.z=-10;this.world.add(board);
  const bg=new Sprite(Gfx.pill(rk.w+14,rk.h+14,'rgba(0,0,0,0)','rgba(128,230,255,.25)',18,false),rk.w+14,rk.h+14);bg.x=rk.cx;bg.y=rk.cy;bg.z=-11;this.world.add(bg);bg.run(A.forever(A.sequence([A.fadeTo(.4,1.2),A.fadeTo(1,1.2)])));
  const pr=this.paddleR;
  for(const s of this.seats){const p={node:new Node(),vel:{x:0,y:0},lives:3,goals:0,outOrder:-1,hearts:[],touch:null,cpuThink:0,cpuAim:{x:0,y:0}};
   const dir=s.dirToScene({dx:0,dy:1}),gc=this.goalCenter(s);let depth;if(s.edge==='bottom'||s.edge==='top')depth=rk.h*(this.n>=3?.33:.46);else depth=rk.w*.4;
   p.home={x:gc.x+dir.dx*(pr+34),y:gc.y+dir.dy*(pr+34)};p.pos={x:p.home.x,y:p.home.y};p.target={x:p.home.x,y:p.home.y};
   if(s.edge==='bottom')p.region={x:rk.x+pr,y:rk.y+pr,w:rk.w-2*pr,h:depth-pr};else if(s.edge==='top')p.region={x:rk.x+pr,y:rk.t-depth,w:rk.w-2*pr,h:depth-pr};
   else if(s.edge==='left')p.region={x:rk.x+pr,y:rk.y+pr,w:depth-pr,h:rk.h-2*pr};else p.region={x:rk.r-depth,y:rk.y+pr,w:depth-pr,h:rk.h-2*pr};
   const rg=p.region,zone=new Sprite(Gfx.pill(rg.w+2*pr,rg.h+2*pr,alpha(s.color,.05),alpha(s.color,.18),12,false),rg.w+2*pr,rg.h+2*pr);zone.x=rg.x+rg.w/2;zone.y=rg.y+rg.h/2;zone.z=-15;this.world.add(zone);
   const glow=new Sprite(Gfx.glow(),pr*4,pr*4);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.55;p.node.add(glow);
   p.node.add(new Sprite(Gfx.circle(pr,alpha(s.color,.95),'#fff'),pr*2,pr*2));const knob=new Sprite(Gfx.circle(pr*.45,white(1,.85),s.color),pr*.9,pr*.9);knob.z=1;p.node.add(knob);
   p.node.x=p.pos.x;p.node.y=p.pos.y;p.node.z=30;this.world.add(p.node);
   const horiz=s.edge==='bottom'||s.edge==='top',gw=horiz?this.goalW:10,gh=horiz?10:this.goalW,g=new Sprite(Gfx.pill(gw,gh,s.color,'#fff',5),gw,gh);g.x=gc.x;g.y=gc.y;g.z=-5;this.world.add(g);
   const gg=new Sprite(Gfx.glow(),gw*1.4,gh*6+30);gg.color=s.color;gg.cbf=1;gg.blend='add';gg.alpha=.45;g.add(gg);p.goalNode=g;
   for(let i=0;i<3;i++){const h=label('♥',20,s.color);h.x=-s.w/2+22+i*22;h.y=-6;h.z=410;s.node.add(h);p.hearts.push(h)}
   const hint=label(s.isCPU?'':'SCHLÄGER ZIEHEN',11,white(1,.55));hint.x=30;hint.y=-8;hint.z=410;s.node.add(hint);hint.run(A.sequence([A.wait(7),A.fadeOut(.5),A.remove()]));
   this.paddles.push(p)}
  this.puck=new Node();const pg=new Sprite(Gfx.glow(),PUCKR*5,PUCKR*5);pg.color=Theme.orange;pg.cbf=1;pg.blend='add';pg.alpha=.6;this.puck.add(pg);this.puckGlow=pg;
  this.puck.add(new Sprite(Gfx.circle(PUCKR,white(.08),Theme.orange),PUCKR*2,PUCKR*2));this.puck.z=25;this.world.add(this.puck);this.resetPuck(null,0)}
 gameStarted(){this.launchPuck(null)}
 goalCenter(s){const r=this.rink;return s.edge==='bottom'?{x:r.cx,y:r.y}:s.edge==='top'?{x:r.cx,y:r.t}:s.edge==='left'?{x:r.x,y:r.cy}:{x:r.r,y:r.cy}}
 resetPuck(seat,delay){this.puckLive=false;this.puckPos={x:this.rink.cx,y:this.rink.cy};this.puckVel={x:0,y:0};this.puck.x=this.puckPos.x;this.puck.y=this.puckPos.y;this.puck.setScale(.1);this.puck.run(A.scaleTo(1,.3));
  if(delay>0)this.run(A.sequence([A.wait(delay),A.run(()=>{if(this.phase==='playing')this.launchPuck(seat)})]))}
 launchPuck(seat){const alive=this.seats.filter(s=>s.alive),t=seat||alive[Math.floor(Math.random()*alive.length)];if(!t)return;const gc=this.goalCenter(t);let dx=gc.x-this.puckPos.x,dy=gc.y-this.puckPos.y;const l=Math.max(1,Math.hypot(dx,dy));dx/=l;dy/=l;
  const a=rr(-.35,.35),sp=230;this.puckVel={x:(dx*Math.cos(a)-dy*Math.sin(a))*sp,y:(dx*Math.sin(a)+dy*Math.cos(a))*sp};this.puckLive=true;this.lastTouch=-1;Sfx.play('whistle')}
 clampR(pt,r){return{x:Math.max(r.x,Math.min(r.x+r.w,pt.x)),y:Math.max(r.y,Math.min(r.y+r.h,pt.y))}}
 began(seat,at,id){const p=this.paddles[seat.index];p.touch=id;p.target=this.clampR(seat.toScene(at),p.region)}
 moved(seat,at,id){const p=this.paddles[seat.index];if(p.touch===null)p.touch=id;if(p.touch===id)p.target=this.clampR(seat.toScene(at),p.region)}
 ended(seat,at,id){const p=this.paddles[seat.index];if(p.touch===id)p.touch=null}
 gameUpdate(dt){
  for(const s of this.seats){if(!s.alive)continue;const p=this.paddles[s.index];if(s.isCPU)this.cpu(s,p,dt);
   const maxV=s.isCPU?140+400*s.skill:2400;let dx=p.target.x-p.pos.x,dy=p.target.y-p.pos.y;const dist=Math.hypot(dx,dy),step=Math.min(dist,maxV*dt);if(dist>.01){dx=dx/dist*step;dy=dy/dist*step}else{dx=0;dy=0}
   p.vel={x:dx/Math.max(dt,.001),y:dy/Math.max(dt,.001)};p.pos.x+=dx;p.pos.y+=dy;p.node.x=p.pos.x;p.node.y=p.pos.y}
  if(!this.puckLive)return;const steps=3,sdt=dt/steps;
  for(let i=0;i<steps;i++){this.puckPos.x+=this.puckVel.x*sdt;this.puckPos.y+=this.puckVel.y*sdt;for(const s of this.seats){if(s.alive)this.collide(s,this.paddles[s.index])}if(this.walls())return}
  const fr=Math.pow(.62,dt);this.puckVel.x*=fr;this.puckVel.y*=fr;let sp=Math.hypot(this.puckVel.x,this.puckVel.y);if(sp>MAXS){this.puckVel.x=this.puckVel.x/sp*MAXS;this.puckVel.y=this.puckVel.y/sp*MAXS;sp=MAXS}
  if(sp<60){this.puckVel.x+=(this.rink.cx-this.puckPos.x)*.4*dt;this.puckVel.y+=(this.rink.cy-this.puckPos.y)*.4*dt}
  this.puck.x=this.puckPos.x;this.puck.y=this.puckPos.y;this.puckGlow.alpha=.4+Math.min(.5,sp/1200);
  this.trailTimer-=dt;if(sp>380&&this.trailTimer<=0){this.trailTimer=.05;const t=new Sprite(Gfx.glow(),PUCKR*2.6,PUCKR*2.6);t.color=Theme.orange;t.cbf=1;t.blend='add';t.alpha=.4;t.x=this.puckPos.x;t.y=this.puckPos.y;t.z=20;this.world.add(t);t.run(A.sequence([A.group([A.fadeOut(.25),A.scaleTo(.3,.25)]),A.remove()]))}}
 collide(s,p){const dx=this.puckPos.x-p.pos.x,dy=this.puckPos.y-p.pos.y,d=Math.hypot(dx,dy),minD=this.paddleR+PUCKR;
  if(d<minD&&d>.001){const nx=dx/d,ny=dy/d;this.puckPos.x=p.pos.x+nx*minD;this.puckPos.y=p.pos.y+ny*minD;const rvx=this.puckVel.x-p.vel.x,rvy=this.puckVel.y-p.vel.y,dot=rvx*nx+rvy*ny;
   if(dot<0){const e=.9;this.puckVel.x-=(1+e)*dot*nx;this.puckVel.y-=(1+e)*dot*ny;this.puckVel.x+=p.vel.x*.25;this.puckVel.y+=p.vel.y*.25;const sp=Math.hypot(this.puckVel.x,this.puckVel.y);
    if(sp>500){Sfx.play('hit');if(!s.isCPU)Haptic.tap('medium');this.sparkAt(this.puckPos,s.color,sp>800?10:5)}else Sfx.play('tap');
    this.lastTouch=s.index;p.node.run(A.sequence([A.scaleTo(1.15,.05),A.scaleTo(1,.08)]))}}}
 sparkAt(p,color,n){for(let i=0;i<n;i++){const d=new Sprite(Gfx.dot(),5,5);d.color=color;d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=35;this.world.add(d);const a=Math.random()*6.28,r=rr(15,55);d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.25),A.fadeOut(.25)]),A.remove()]))}}
 seatAt(e){return this.seats.find(s=>s.edge===e)}
 walls(){const r=this.rink,half=this.goalW/2,pp=this.puckPos,pv=this.puckVel;let s;
  if(pp.y-PUCKR<r.y){if((s=this.seatAt('bottom'))&&s.alive&&Math.abs(pp.x-r.cx)<half-PUCKR*.3){if(pp.y<r.y-PUCKR){this.goal(s);return true}}else{pp.y=r.y+PUCKR;pv.y=Math.abs(pv.y)*.92;this.boardHit()}}
  if(pp.y+PUCKR>r.t){if((s=this.seatAt('top'))&&s.alive&&Math.abs(pp.x-r.cx)<half-PUCKR*.3){if(pp.y>r.t+PUCKR){this.goal(s);return true}}else{pp.y=r.t-PUCKR;pv.y=-Math.abs(pv.y)*.92;this.boardHit()}}
  if(pp.x-PUCKR<r.x){if((s=this.seatAt('left'))&&s.alive&&Math.abs(pp.y-r.cy)<half-PUCKR*.3){if(pp.x<r.x-PUCKR){this.goal(s);return true}}else{pp.x=r.x+PUCKR;pv.x=Math.abs(pv.x)*.92;this.boardHit()}}
  if(pp.x+PUCKR>r.r){if((s=this.seatAt('right'))&&s.alive&&Math.abs(pp.y-r.cy)<half-PUCKR*.3){if(pp.x>r.r+PUCKR){this.goal(s);return true}}else{pp.x=r.r-PUCKR;pv.x=-Math.abs(pv.x)*.92;this.boardHit()}}
  return false}
 boardHit(){if(Math.hypot(this.puckVel.x,this.puckVel.y)>300)Sfx.play('bounce')}
 goal(s){const p=this.paddles[s.index];this.puckLive=false;this.puck.x=this.puckPos.x;this.puck.y=this.puckPos.y;p.lives--;
  if(p.lives>=0&&p.lives<p.hearts.length)p.hearts[p.lives].run(A.group([A.scaleTo(1.8,.2),A.fadeTo(.15,.2)]));
  if(this.lastTouch>=0&&this.lastTouch!==s.index){const sc=this.seats[this.lastTouch];this.paddles[this.lastTouch].goals++;this.addScore(sc,1);this.addStat('goals',1,sc);sc.banner('TOR!','#ff0',30,.6)}
  Sfx.play('goal');Haptic.bad();const gc=this.goalCenter(s);this.ptBurst(gc,s.color);this.flashAll(s.color,.28);
  this.world.run(A.sequence([A.moveBy(9,0,.03),A.moveBy(-18,0,.05),A.moveBy(9,0,.03)]));s.flash(s.color);
  const ring=new Sprite(Gfx.circle(20,'rgba(0,0,0,0)','#fff'),40,40);ring.blend='add';ring.x=gc.x;ring.y=gc.y;ring.z=40;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(7,.5),A.fadeOut(.5)]),A.remove()]));
  if(p.lives<=0){p.outOrder=this.outCount++;s.knockOut('RAUS');p.node.run(A.fadeTo(.15,.3));p.goalNode.color='#fff';p.goalNode.cbf=1;p.goalNode.alpha=.6;Sfx.play('lose')}
  if(this.aliveSeats.length<=1){this.finishGame(this.finalScores());return}
  this.resetPuck(s.alive?s:null,1.1)}
 ptBurst(p,color){for(let i=0;i<26;i++){const d=new Sprite(Gfx.dot(),8,8);d.color=color;d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=40;this.world.add(d);const a=Math.random()*6.28,r=rr(40,160);d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.5),A.fadeOut(.5)]),A.remove()]))}}
 finalScores(){return this.seats.map(s=>{const p=this.paddles[s.index],surv=p.outOrder>=0?p.outOrder:this.n;return Math.max(0,p.lives)*1000+surv*100+p.goals})}
 timeUp(){this.finishGame(this.finalScores())}
 cpu(s,p,dt){p.cpuThink-=dt;if(p.cpuThink>0){p.target=this.clampR(p.cpuAim,p.region);return}p.cpuThink=.08+(1-s.skill)*.32;const gc=this.goalCenter(s),inward=s.dirToScene({dx:0,dy:1}),pp=this.puckPos,pv=this.puckVel,pr=this.paddleR;
  const toGoal={x:gc.x-pp.x,y:gc.y-pp.y},approaching=pv.x*toGoal.x+pv.y*toGoal.y>0,rg=p.region,inRegion=pp.x>=rg.x-pr*1.5&&pp.x<=rg.x+rg.w+pr*1.5&&pp.y>=rg.y-pr*1.5&&pp.y<=rg.y+rg.h+pr*1.5,err=(1-s.skill)*48;
  if(this.puckLive&&inRegion){const dx=pp.x-gc.x,dy=pp.y-gc.y,l=Math.max(1,Math.hypot(dx,dy)),behind={x:pp.x-dx/l*(pr*.6),y:pp.y-dy/l*(pr*.6)},paddleBehind=(p.pos.x-gc.x)*dx+(p.pos.y-gc.y)*dy<(l-6)*l;p.cpuAim=paddleBehind?{x:pp.x+dx/l*30,y:pp.y+dy/l*30}:behind}
  else if(this.puckLive&&approaching){const t=.35;p.cpuAim={x:gc.x+(pp.x-gc.x)*t+inward.dx*40,y:gc.y+(pp.y-gc.y)*t+inward.dy*40}}
  else{const lat={x:inward.dy,y:-inward.dx},off=(pp.x-gc.x)*lat.x+(pp.y-gc.y)*lat.y,o=Math.max(-this.goalW*.4,Math.min(this.goalW*.4,off*.5));p.cpuAim={x:p.home.x+lat.x*o,y:p.home.y+lat.y*o}}
  p.cpuAim.x+=rr(-err,err);p.cpuAim.y+=rr(-err,err);p.target=this.clampR(p.cpuAim,p.region)}
}
Arcade.register('airhockey',AirHockeyGame);
})();
