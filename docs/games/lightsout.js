(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ON=rgba(1,.82,.2),OFF=rgba(.12,.13,.2),TOTAL=3;
const apply=(b,c,g)=>{const col=c%g,row=Math.floor(c/g);b[c]=!b[c];if(col>0)b[c-1]=!b[c-1];if(col<g-1)b[c+1]=!b[c+1];if(row>0)b[c-g]=!b[c-g];if(row<g-1)b[c+g]=!b[c+g]};
class LightsOutGame extends MiniScene{
 setupGame(){this.duration=45;this.g=this.n===2?4:3;const g=this.g,r=this.newRand();this.puzzles=[];this.solved=[0,0,0];this.states=[];this.ending=false;
  for(let k=0;k<TOTAL;k++){for(;;){const board=Array(g*g).fill(false),set=new Set(),cnt=g===3?r.int(3,5):r.int(5,7);
    for(let i=0;i<cnt;i++){const c=r.int(0,g*g-1);if(set.has(c))set.delete(c);else set.add(c)}
    for(const c of set)apply(board,c,g);
    if(set.size>=2&&board.includes(true)){this.puzzles.push({board,sol:[...set].sort((a,b)=>a-b)});break}}}
  for(const s of this.seats){const st={cells:[],glows:[],dots:[],board:[],progress:0,locked:true,done:false,queue:[],timer:1};
   this.cs=Math.floor(Math.min((s.w-24)/g,(s.h-80)/g,76));const cs=this.cs,gs=cs*g;this.gx0=-gs/2;this.gy0=-gs/2+1;
   for(let i=0;i<g*g;i++){const col=i%g,row=Math.floor(i/g),px=this.gx0+(col+.5)*cs,py=this.gy0+(row+.5)*cs;
    const glow=new Sprite(Gfx.glow(),cs*1.7,cs*1.7);glow.blend='add';glow.color=ON;glow.cbf=1;glow.alpha=0;glow.x=px;glow.y=py;glow.z=1;s.field.add(glow);
    const c=new Sprite(Gfx.pill(cs-6,cs-6,'#fff',white(1,.25),10),cs-6,cs-6);c.color=OFF;c.cbf=1;c.x=px;c.y=py;c.z=2;s.field.add(c);st.cells.push(c);st.glows.push(glow)}
   for(let k=0;k<TOTAL;k++){const d=new Sprite(Gfx.circle(6,'#fff'),12,12);d.color=white(.3);d.cbf=1;d.x=(k-1)*22;d.y=-s.h/2+18;d.z=3;s.field.add(d);st.dots.push(d)}
   const hint=label('FELD + NACHBARN UMSCHALTEN',Math.min(11,s.w*.055),white(1,.8));hint.y=-s.h/2+38;hint.z=3;s.field.add(hint);st.hint=hint;
   this.loadPuzzle(s,st);this.states.push(st)}}
 loadPuzzle(s,st){const pz=this.puzzles[st.progress];st.board=pz.board.slice();for(let i=0;i<this.g*this.g;i++)this.paint(st,i,false);
  const q=pz.sol.slice();for(let i=q.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[q[i],q[j]]=[q[j],q[i]]}st.queue=q;st.timer=.6+(1-s.skill)*1.2}
 paint(st,i,pop){const lit=st.board[i];st.cells[i].color=lit?ON:OFF;st.glows[i].alpha=lit?.85:0;if(pop){st.cells[i].removeAction('pop');st.cells[i].run(A.sequence([A.scaleTo(.82,.05),A.scaleTo(1,.1)]),'pop')}}
 gameStarted(){for(const st of this.states)st.locked=false;for(const s of this.seats)this.states[s.index].hint.run(A.sequence([A.wait(5),A.fadeOut(.5)]))}
 tap(s,c){const st=this.states[s.index];if(st.locked||st.done)return;const g=this.g;apply(st.board,c,g);const col=c%g,row=Math.floor(c/g),idx=[c];
  if(col>0)idx.push(c-1);if(col<g-1)idx.push(c+1);if(row>0)idx.push(c-g);if(row<g-1)idx.push(c+g);for(const i of idx)this.paint(st,i,true);
  if(!s.isCPU){Sfx.play('tap');Haptic.tap()}if(!st.board.includes(true))this.solve(s,st)}
 solve(s,st){const k=st.progress,pts=Math.max(1,3-this.solved[k]);this.solved[k]++;this.addScore(s,pts);st.dots[k].color=pts===3?ON:s.color;st.locked=true;
  s.floatText('+'+pts,{x:0,y:20},'#ff0',34);s.burst({x:0,y:0},ON,22,160);s.flash(ON,.25);if(!s.isCPU){Sfx.play(pts===3?'fanfare':'coin');Haptic.good()}
  st.progress++;if(st.progress>=TOTAL){st.done=true;s.banner('FERTIG!',ON,38,1.5);return}
  s.field.run(A.sequence([A.wait(.7),A.run(()=>{this.loadPuzzle(s,st);st.locked=false})]))}
 gameUpdate(dt){for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(st.locked||st.done)continue;st.timer-=dt;
   if(st.timer<=0&&st.queue.length){this.tap(s,st.queue.shift());st.timer=.3+(1-s.skill)*1.1+Math.random()*.3}}
  if(!this.ending&&this.states.every(s=>s.done)){this.ending=true;this.finishGame()}}
 began(seat,at){const col=Math.floor((at.x-this.gx0)/this.cs),row=Math.floor((at.y-this.gy0)/this.cs),g=this.g;if(col<0||col>=g||row<0||row>=g)return;this.tap(seat,row*g+col)}
}
Arcade.register('lightsout',LightsOutGame);
})();
