(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
const ROUNDS=6;
class PatternGame extends MiniScene{
 setupGame(){this.duration=0;this.round=0;this.stage='idle';this.timer=1;this.rand=this.newRand();this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),g=3,cs=Math.min((p.w-30)/g,(p.h-60)/g,92),st={p,cs,cells:[],picked:[],done:false,fail:false,cpuT:0};
  for(let i=0;i<9;i++){const x=(i%3-1)*cs,y=p.cy-(Math.floor(i/3)-1)*cs,c=new Sprite(Gfx.pill(cs-8,cs-8,white(1,.12),white(1,.35),14,false),cs-8,cs-8);c.x=x;c.y=y;c.z=2;c.color=white(1,.12);s.field.add(c);st.cells.push({c,x,y,s:cs})}
  st.info=label('',16,'#fff');st.info.y=p.cy+p.h/2-22;st.info.z=9;s.field.add(st.info);return st})}
 gameStarted(){this.next()}
 next(){this.round++;const k=2+Math.ceil(this.round*.8),cells=[];while(cells.length<k){const c=this.rand.int(0,8);if(!cells.includes(c))cells.push(c)}this.pat=cells;this.stage='show';this.timer=.9+k*.35;
  for(const s of this.seats){const st=this.st[s.index];st.picked=[];st.done=false;st.fail=false;st.info.text='MERKEN… ('+this.round+'/'+ROUNDS+')';st.cpuT=NK.rr(.5,1)+(1-s.skill)*1.2;st.cells.forEach((q,i)=>{q.c.alpha=1;q.c.color=cells.includes(i)?s.color:white(1,.12)})}Sfx.play('beep')}
 gameUpdate(dt){this.timer-=dt;
  if(this.stage==='show'&&this.timer<=0){this.stage='input';this.timer=3+this.pat.length*1.4;for(const s of this.seats){const st=this.st[s.index];st.info.text='JETZT!';st.cells.forEach(q=>q.c.color=white(1,.12))}Sfx.play('go')}
  else if(this.stage==='input'){for(const s of this.seats){if(!s.isCPU)continue;const st=this.st[s.index];if(st.done||st.fail)continue;st.cpuT-=dt;if(st.cpuT<=0){st.cpuT=NK.rr(.35,.7)+(1-s.skill)*.4;const rem=this.pat.filter(c=>!st.picked.includes(c));const wrong=Math.random()<(1-s.skill)*.12;this.tap(s,wrong?Math.floor(Math.random()*9):rem[0])}}
   if(this.timer<=0||this.seats.every(s=>this.st[s.index].done||this.st[s.index].fail)){this.stage='gap';this.timer=1.3;for(const s of this.seats){const st=this.st[s.index];if(!st.done&&!st.fail){st.fail=true;st.info.text='ZU LANGSAM'}if(st.fail)this.pat.forEach(c=>{st.cells[c].c.color=NK.al(s.color,.4)})}}}
  else if(this.stage==='gap'&&this.timer<=0){if(this.round>=ROUNDS)this.finishGame();else this.next()}}
 began(s,at){if(this.stage!=='input')return;const st=this.st[s.index];let b=-1,bd=1e9;st.cells.forEach((q,i)=>{const d=Math.hypot(q.x-at.x,q.y-at.y);if(d<q.s*.55&&d<bd){bd=d;b=i}});if(b>=0)this.tap(s,b)}
 tap(s,i){const st=this.st[s.index];if(st.done||st.fail||st.picked.includes(i))return;const q=st.cells[i],pos={x:q.x,y:q.y};
  if(this.pat.includes(i)){st.picked.push(i);q.c.color=s.color;q.c.run(A.sequence([A.scaleTo(1.15,.06),A.scaleTo(1,.08)]));Sfx.play('tap');if(!s.isCPU)Haptic.tap('light');
   if(st.picked.length===this.pat.length){st.done=true;const pts=this.pat.length+(this.seats.filter(o=>this.st[o.index].done).length===1?1:0);this.addScore(s,pts);this.addStat('hits',1,s);st.info.text='PERFEKT! +'+pts;s.floatText('+'+pts,{x:0,y:st.p.cy},'#ff0',28);s.burst({x:0,y:st.p.cy},s.color,16,140);Sfx.play('coin')}}
  else{st.fail=true;q.c.color='#ff3b3b';st.info.text='FALSCH';s.flash('#f00',.25);s.shake(4);Sfx.play('wrong');if(!s.isCPU)Haptic.bad&&Haptic.bad()}}
}
Arcade.register('pattern',PatternGame);})();
