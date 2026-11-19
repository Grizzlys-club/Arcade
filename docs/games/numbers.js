(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COUNT=12,ROUNDS=3;
class NumbersGame extends MiniScene{
 setupGame(){this.rand=this.newRand();this.round=0;this.states=[];this.positions=[];this.finishOrder=[];this.roundActive=false;this.roundTime=0;this.pauseT=0;
  const s0=this.seats[0],area=(s0.w-16)*(s0.h-60);this.radius=Math.min(30,Math.max(18,Math.sqrt(area/COUNT)*.36));
  for(const s of this.seats){const st={bubbles:[],next:1,frozen:0,finished:false,cpuTimer:0,container:new Node()};st.container.z=5;s.field.add(st.container);
   const hint=label('TIPPE 1 → 12',Math.min(18,s.w*.085),s.color);hint.y=s.h/2-44;hint.z=10;s.field.add(hint);st.hint=hint;this.states.push(st)}}
 gameStarted(){this.startRound()}
 makeLayout(){const s0=this.seats[0],r=this.radius,minX=-s0.w/2+r+8,maxX=s0.w/2-r-8,minY=-s0.h/2+r+10,maxY=s0.h/2-58-r;let pts=[],tries=0,minDist=r*2.25;
  while(pts.length<COUNT){tries++;if(tries>4000){minDist*=.92;tries=0;pts=[]}const p={x:this.rand.range(minX,maxX),y:this.rand.range(minY,maxY)};if(pts.every(q=>Math.hypot(q.x-p.x,q.y-p.y)>=minDist))pts.push(p)}
  this.positions=pts}
 startRound(){this.round++;this.makeLayout();this.finishOrder=[];this.roundActive=true;this.roundTime=0;
  for(const s of this.seats){const st=this.states[s.index];st.container.children.slice().forEach(c=>c.removeFromParent());st.bubbles=[];st.next=1;st.finished=false;st.frozen=0;st.cpuTimer=.8+Math.random()*.3;
   st.hint.text=s.w<300?'RUNDE '+this.round+'/'+ROUNDS:'RUNDE '+this.round+'/'+ROUNDS+' · TIPPE 1 → '+COUNT;
   for(let i=0;i<COUNT;i++){const b=new Sprite(Gfx.circle(this.radius,white(.12,.95),s.color),this.radius*2,this.radius*2);b.x=this.positions[i].x;b.y=this.positions[i].y;b.z=1;
    const l=label(''+(i+1),this.radius*.95,'#fff');l.z=1;b.add(l);b.setScale(0);b.run(A.sequence([A.wait(i*.02),A.scaleTo(1,.15)]));st.container.add(b);st.bubbles.push(b)}
   const st2=st;if(this.round===1){const b=st2.bubbles[0];b.run(A.forever(A.sequence([A.scaleTo(1.12,.35),A.scaleTo(1,.35)])),'pulse')}}}
 gameUpdate(dt){if(!this.roundActive){this.pauseT-=dt;if(this.pauseT<=0&&this.phase==='playing'){if(this.round>=ROUNDS)this.finishGame();else this.startRound()}return}
  this.roundTime+=dt;
  for(const s of this.seats){const st=this.states[s.index];if(st.frozen>0)st.frozen-=dt;
   if(s.isCPU&&!st.finished&&st.frozen<=0){st.cpuTimer-=dt;if(st.cpuTimer<=0){st.cpuTimer=.42+(1-s.skill)*.6+Math.random()*.25;
    if(Math.random()<.02+.06*(1-s.skill)){let w=1+Math.floor(Math.random()*COUNT);if(w===st.next)w=w%COUNT+1;this.tap(s,w)}else this.tap(s,st.next)}}}
  if(this.roundTime>22||this.seats.every(s=>this.states[s.index].finished))this.endRound()}
 tap(s,number){const st=this.states[s.index];if(st.finished||st.frozen>0||!this.roundActive)return;
  if(number===st.next){const b=st.bubbles[number-1];b.removeAction('pulse');b.run(A.sequence([A.group([A.scaleTo(1.5,.12),A.fadeOut(.12)]),A.remove()]));s.burst({x:b.x,y:b.y},s.color,6,60);
   if(!s.isCPU){Sfx.play('pop');Haptic.tap()}st.next++;
   if(st.next>COUNT){st.finished=true;this.finishOrder.push(s.index);const place=this.finishOrder.length,pts=this.n-place+1;this.addScore(s,pts);
    s.banner(place===1?'ERSTER!':place+'. PLATZ',place===1?'#ff0':s.color,36,1);s.floatText('+'+pts,{x:0,y:-40},'#ff0',28);if(!s.isCPU)Sfx.play(place===1?'right':'coin')}
   else if(this.round===1&&st.next===2){}}
  else{st.frozen=.8;s.flash('#f00',.35);s.shake(4);if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}
   if(number>=1&&number<=COUNT){const b=st.bubbles[number-1];if(b.parent)b.run(A.sequence([A.moveBy(6,0,.04),A.moveBy(-12,0,.08),A.moveBy(6,0,.04)]))}}}
 endRound(){this.roundActive=false;this.pauseT=1.6;for(const s of this.seats)if(!this.states[s.index].finished)s.floatText('ZEIT UM',{x:0,y:0},white(1,.8),24)}
 began(seat,at){const st=this.states[seat.index];let bi=-1,bd=this.radius*1.25;st.bubbles.forEach((b,i)=>{if(b.parent&&i+1>=st.next){const d=Math.hypot(b.x-at.x,b.y-at.y);if(d<bd){bd=d;bi=i}}});if(bi>=0)this.tap(seat,bi+1)}
}
Arcade.register('numbers',NumbersGame);
})();
