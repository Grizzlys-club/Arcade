(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const RACE=60,PP=[100,80,60,40];
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const finishTex=()=>Gfx.texture('sprint_finish',120,12,2,c=>{for(let i=0;i<20;i++)for(let j=0;j<2;j++){c.fillStyle=((i+j)%2===0)?'#fff':'#000';c.fillRect(i*6,j*6,6,6)}});
class TapSprintGame extends MiniScene{
 setupGame(){this.duration=25;this.st=[];this.finishOrder=[];
  for(const s of this.seats){const g={dist:0,vel:0,lastSide:0,stumble:0,finishedPlace:-1,markers:[],cpuT:0,running:false},btnH=Math.min(70,s.h*.18),btnY=-s.h/2+10+btnH/2;
   g.startY=btnY+btnH/2+34;g.finishY=s.h/2-52;const trackW=Math.min(s.w*.5,130),trackX=-Math.min(14,s.w*.06),trackH=g.finishY-g.startY+40;
   const track=new Sprite(Gfx.pill(trackW,trackH,rgba(.55,.18,.12,.85),alpha(s.color,.8),8),trackW,trackH);track.x=trackX;track.y=(g.finishY+g.startY)/2;track.z=-5;s.field.add(track);
   for(let m=10;m<RACE;m+=10){const y=g.startY+m/RACE*(g.finishY-g.startY),line=new Sprite(null,trackW-8,2,white(1,.35));line.x=trackX;line.y=y;line.z=-4;s.field.add(line);
    const l=label(''+m,10,white(1,.5));l.ha='left';l.x=trackX+trackW/2+4;l.y=y;s.field.add(l)}
   const fin=new Sprite(finishTex(),trackW-4,10);fin.x=trackX;fin.y=g.finishY;fin.z=-3;s.field.add(fin);
   const start=new Sprite(null,trackW-4,3,'#fff');start.x=trackX;start.y=g.startY;start.z=-3;s.field.add(start);
   const bh=Math.min(48,s.w*.22),bear=this.makeBear(s,bh);bear.x=trackX;bear.y=g.startY-6;bear.z=10;s.field.add(bear);bear.startBob(2,.4);g.bear=bear;
   const bw=s.w/2-16,lb=this.button('◀ L',bw,btnH,s.color,'#fff',Math.min(24,btnH*.38));lb.x=-s.w/4;lb.y=btnY;lb.z=20;s.field.add(lb);
   const rb=this.button('R ▶',bw,btnH,s.color,'#fff',Math.min(24,btnH*.38));rb.x=s.w/4;rb.y=btnY;rb.z=20;s.field.add(rb);g.leftBtn=lb;g.rightBtn=rb;
   g.barBottom=g.startY;g.barTop=g.finishY;const barX=s.w/2-12,bar=new Sprite(null,4,g.barTop-g.barBottom,white(1,.15));bar.x=barX;bar.y=(g.barTop+g.barBottom)/2;s.field.add(bar);
   for(const o of this.seats){const me=o.index===s.index,mk=new Sprite(Gfx.circle(6,o.color,me?'#fff':null),me?13:10,me?13:10);mk.x=barX;mk.y=g.barBottom;mk.z=me?6:5;s.field.add(mk);g.markers.push(mk)}
   g.meterLabel=label('0 m',12,white(1,.75));g.meterLabel.ha='left';g.meterLabel.x=-s.w/2+14;g.meterLabel.y=s.h/2-34;g.meterLabel.z=30;s.node.add(g.meterLabel);this.st.push(g);
   const hint=label('ABWECHSELND TIPPEN!',Math.min(15,s.w*.072),'#fff');hint.y=g.startY+50;hint.z=40;s.field.add(hint);hint.run(A.sequence([A.wait(4.6),A.fadeOut(.4),A.remove()]))}}
 press(s,side){const g=this.st[s.index];if(g.finishedPlace>=0)return;const btn=side<0?g.leftBtn:g.rightBtn;btn.removeAction('press');btn.run(A.sequence([A.scaleTo(.9,.04),A.scaleTo(1,.07)]),'press');
  if(g.stumble>0)return;
  if(side===g.lastSide){g.vel*=.3;g.stumble=.35;g.bear.squash();s.floatText('STOLPERT!',{x:g.bear.x,y:g.bear.y+50},rgba(1,.4,.4),15);Sfx.play('wrong');if(!s.isCPU)Haptic.bad();g.lastSide=0;return}
  g.lastSide=side;g.vel=Math.min(11,g.vel+1);if(!s.isCPU)Haptic.tap();Sfx.play('tap')}
 finishRunner(s){const g=this.st[s.index];g.finishedPlace=this.finishOrder.length;this.finishOrder.push(s.index);const pts=PP[Math.min(g.finishedPlace,PP.length-1)];this.setScore(s,pts);
  g.bear.stopRun();g.bear.stopBob();g.bear.celebrate();s.banner(g.finishedPlace===0?'1. PLATZ!':(g.finishedPlace+1)+'. PLATZ',g.finishedPlace===0?'#ff0':'#fff',32,1.2);
  s.burst({x:g.bear.x,y:g.finishY},'#ff0',18,120);Sfx.play(g.finishedPlace===0?'fanfare':'whistle');if(!s.isCPU)Haptic.good()}
 gameUpdate(d){for(const s of this.seats){const g=this.st[s.index];if(g.finishedPlace>=0)continue;if(s.isCPU)this.cpu(s,d);if(g.stumble>0)g.stumble-=d;
   g.vel*=Math.max(0,1-1.2*d);if(g.vel<.05)g.vel=0;g.dist=Math.min(RACE,g.dist+g.vel*d);const y=g.startY+g.dist/RACE*(g.finishY-g.startY);g.bear.y=y-6;
   if(g.vel>.8&&!g.running){g.running=true;g.bear.stopBob();g.bear.startRun(.12)}else if(g.vel<=.8&&g.running){g.running=false;g.bear.stopRun();g.bear.startBob(2,.4)}
   g.meterLabel.text=Math.floor(g.dist)+' m';if(g.dist>=RACE)this.finishRunner(s)}
  for(const s of this.seats){const g=this.st[s.index];for(const o of this.seats)g.markers[o.index].y=g.barBottom+this.st[o.index].dist/RACE*(g.barTop-g.barBottom)}
  if(this.finishOrder.length>=this.seats.length)this.endRace()}
 cpu(s,dt){const g=this.st[s.index];g.cpuT-=dt;if(g.cpuT>0)return;const rate=3+s.skill*4.5;g.cpuT=1/rate*(.8+Math.random()*.4);let side=g.lastSide===0?1:-g.lastSide;
  if(g.lastSide!==0&&Math.random()<(1-s.skill)*.07)side=g.lastSide;this.press(s,side)}
 endRace(){if(this.finished)return;const scores=this.seats.map(s=>{const g=this.st[s.index];return g.finishedPlace>=0?PP[Math.min(g.finishedPlace,PP.length-1)]:Math.floor(g.dist/RACE*39)});
  this.seats.forEach((s,i)=>this.setScore(s,scores[i]));this.finishGame(scores)}
 timeUp(){this.endRace()}
 began(seat,at){this.press(seat,at.x<0?-1:1)}
}
Arcade.register('tapsprint',TapSprintGame);
})();
